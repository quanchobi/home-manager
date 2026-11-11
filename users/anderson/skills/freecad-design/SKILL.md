---
name: freecad-design
description: Design 3D-printable parts in FreeCAD through the freecad-mcp server (mcp__freecad_* tools). Use for any CAD/3D-modeling/3D-printing request: brackets, holders, clips, enclosures, STL/STEP export, fitting parts to measured objects.
---

# FreeCAD design via MCP

FreeCAD 1.1 (snap) + the `freecad-mcp` server. Tools appear as `mcp__freecad_*` once FreeCAD is running. Deliverables: STL (print), STEP (CAD exchange), FCStd (editable, parametric), preview PNG, and the build script.

## 1. Start FreeCAD

FreeCAD does not run after a reboot. The MCP tools need its GUI RPC server (`127.0.0.1:9875`), which the addon auto-starts:

```bash
~/.omp/agent/skills/freecad-design/scripts/start-freecad.sh    # idempotent; opens FreeCAD in niri-agent session "freecad"
```

It runs FreeCAD inside a private niri-agent session (see `skill://niri-agent`), so it never touches the user's desktop. Then call `mcp__freecad_get_rpc_status`; expect `"state": "healthy"` and `"version_check": "ok"`. When finished: `niri-agent stop freecad`.

If the `mcp__freecad_*` tools are missing from the session (config: `~/.omp/agent/mcp.json`), use the CLI client, which speaks the same MCP protocol:

```bash
uv run -q --with mcp python ~/.omp/agent/skills/freecad-design/scripts/mcp_call.py execute_code @build.py
uv run -q --with mcp python ~/.omp/agent/skills/freecad-design/scripts/mcp_call.py get_view '{"view_name":"Right"}'
```

Images land in `$MCP_SHOT_DIR` (default cwd) as `shot_<n>.png`; exit code 1 on failure.

## 2. Tools that matter

| Tool                         | Use                                                                                                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `execute_code`               | Main workhorse: run a Python build script on the GUI thread. Returns stdout + isometric screenshot. Pass `include_screenshot: false` for probes.        |
| `get_view`                   | Screenshot: `view_name` = Isometric/Front/Top/Right/Left/Back/Bottom/Dimetric/Trimetric. `Right` looks down +X, i.e. end-on for parts extruded along X. |
| `execute_code_headless`      | Separate `freecad.cmd` process: heavy OCCT work, or when no GUI is needed. Script must import modules and save files itself.                            |
| `get_rpc_status`             | Health check; does not use the GUI thread.                                                                                                              |
| `get_objects` / `get_object` | Inspect document state.                                                                                                                                 |

Failures come back as text (`Failed to execute code: ...`, `Headless FreeCAD script FAILED`), **not** as MCP errors. Read the text.

## 3. Environment gotchas (all verified)

- **Snap sees a private `/tmp`.** Files FreeCAD writes to `/tmp` are invisible to the host and vice versa. Use non-hidden paths under `$HOME` (e.g. `~/<project>/`). Hidden dirs (`~/.cache`, `~/.config`) are unreadable to the snap.
- **Headless needs a symlink:** the server writes scripts to `~/.cache/freecad-mcp/headless`, which is a symlink to `~/snap/freecad/common/mcp-headless`. If headless fails with `PermissionError ... .cache/freecad-mcp/headless`, recreate it: `rm -rf ~/.cache/freecad-mcp/headless && ln -s ~/snap/freecad/common/mcp-headless ~/.cache/freecad-mcp/headless`.
- **niri-agent needs `--host-bus` for the snap.** On the private bus snapd cannot create its systemd scope and FreeCAD exits instantly (the start script handles this).
- **Addon/server sync:** addon lives in `~/snap/freecad/common/Mod/FreeCADMCP` (copied from github.com/neka-nat/freecad-mcp `addon/FreeCADMCP`); server is `uvx freecad-mcp` (latest from PyPI). If `version_check` is not `ok`, re-copy the addon from a fresh clone and restart FreeCAD. Addon settings: `~/snap/freecad/common/freecad_mcp_settings.json` (`auto_start_rpc: true`).
- `execute_code` scripts share one persistent namespace; re-running a build script should `App.closeDocument(NAME)` first.

## 4. Design workflow

1. **Pin down the mating geometry.** Ask for caliper measurements of anything the part touches. Photos: crop and level the silhouette, scale pixels from the known measurements, and label derived numbers "photo estimate" in the Params notes and in the report. Name the one dimension most likely to break the fit and ask the user to confirm it.
2. **Write a build script file** (copy `~/.omp/agent/skills/freecad-design/templates/parametric_part.py`) in the project dir, and run it through `execute_code`. Keep it re-runnable; it is the source of truth.
   - All dimensions go in a `Params` spreadsheet with aliases; features use `setExpression(...)` so the FCStd stays editable.
   - Primitives (`Part::Box/Cylinder/Cone`) + `Part::MultiFuse` / `Part::Cut` with `Refine = True`.
   - Odd cross-sections: fully constrained `Sketcher::SketchObject` with named, expression-driven constraints; `Part::Offset2D` (Join=0, rounded) of that sketch gives the clearance cavity (offset = clearance) and the outer shell (clearance + wall); then `Part::Extrusion` (Solid, Symmetric). Sketch in the global YZ plane: `App.Rotation(App.Vector(1,1,1), 120)`; sketch x → Y, sketch y → Z, extrude along X.
   - Add hidden-from-export reference bodies (the mated object, magnets, screws) in a `Reference` group, semi-transparent, for previews and interference checks.
   - For variants (e.g. multiple magnet sizes), wrap the build in a function looped over a list; one document/file set per variant with a size suffix.
3. **Verify geometrically, not just visually:**
   - `shape.isValid()`, exactly 1 solid, sketch `FullyConstrained` with no malformed/redundant/conflicting constraints.
   - Probe critical dimensions with `shape.common(Part.makeLine(a, b))` intervals: hole diameters, wall/floor thickness, top surface height.
   - Interference: `reference.Shape.common(part).Volume == 0`.
   - Mesh: `isSolid()` true, `hasNonManifolds()` false.
   - Flex one parameter, recompute, confirm the part stays valid, then restore it.
   - Look at `get_view` Isometric and an end-on view.
4. **Export** FCStd + STEP + STL (`tessellate(0.01)`), save a preview PNG, delete scratch files (`*.FCBak`, probe scripts, shots).
5. **Report:** dimensions table, what was measured vs estimated, print orientation (avoid supports: put round holes horizontal or pockets facing up; lay profiles flat), and which Params to tweak if the fit is off.

## 5. This user's printer: calibrated fits

Confirmed by real prints. Use these as defaults:

| Fit                         | Value                          | Evidence                                                                  |
| --------------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| Sliding fit over an object  | **0.4 mm per side** clearance  | T8 tube holder: "fitment was perfect"                                     |
| Magnet press-fit pocket     | **nominal diameter (+0.0 mm)** | +0.1 mm was "a little bit loose" (Oct 2026); +0.0 not yet print-confirmed |
| Magnet pocket depth         | magnet thickness + 0.1 mm      | User likes magnets sitting slightly proud (stronger hold)                 |
| Floor under a magnet pocket | 1.2 mm                         | Printed fine                                                              |
| Wall                        | 2.5 mm                         | Printed fine                                                              |

Update this table when the user reports fit results.

## Worked example

`~/tube_holder/build_holder.py`: magnet holder for an Anern T8 LED tube with a flanged V profile. It covers the spreadsheet, the constrained sketch with expressions, Offset2D shells, variant loop, probes, and exports.
