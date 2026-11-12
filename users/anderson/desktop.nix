# Desktop (yappy-yiqi) only: local llama.cpp models, CAD/ComfyUI MCP servers.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # From nixpkgs, so the servers don't depend on a hand-installed uv on PATH.
  uvx = lib.getExe' pkgs.uv "uvx";

  # Pinned: unpinned uvx runs whatever PyPI has at each omp start. Bump
  # freecad-mcp together with the FreeCAD addon (same tag, see SKILL.md).
  freecadMcp = "freecad-mcp@0.1.30";
  blenderMcp = "mcp-for-blender@2.2.7";

  # The skill's CLI client runs on a Nix Python with the MCP SDK and starts the
  # same pinned server as omp's mcp.json.
  freecadSkill = pkgs.runCommand "freecad-design-skill" { } ''
    cp -r ${./skills/freecad-design} $out
    chmod -R u+w $out
    substituteInPlace $out/scripts/mcp_call.py \
      --replace-fail @python@ ${lib.getExe' (pkgs.python3.withPackages (ps: [ ps.mcp ])) "python3"} \
      --replace-fail @uvx@ ${uvx} \
      --replace-fail @freecadMcp@ ${freecadMcp}
    substituteInPlace $out/SKILL.md --replace-fail @freecadMcp@ ${freecadMcp}
    chmod +x $out/scripts/mcp_call.py
  '';

  # omp rewrites mcp.json itself (/mcp add, enable, disable, reauth), so these
  # servers are merged into it on activation, like config.yml in ./omp.nix. The
  # merge only adds: a server removed here stays in mcp.json until deleted there.
  mcpServers = (pkgs.formats.json { }).generate "omp-mcp.json" {
    "$schema" =
      "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
    mcpServers = {
      freecad = {
        type = "stdio";
        command = uvx;
        args = [ freecadMcp ];
        timeout = 660000;
      };
      blender = {
        type = "stdio";
        command = uvx;
        args = [ blenderMcp ];
        timeout = 660000;
      };
      comfyui = {
        type = "stdio";
        command = "${config.home.homeDirectory}/.local/bin/comfyui-mcp";
        args = [
          "--comfyui-url"
          "http://127.0.0.1:8188"
        ];
        timeout = 660000;
      };
    };
  };
in
{
  home.file = {
    ".omp/agent/models.yml".source = (pkgs.formats.yaml { }).generate "omp-models.yml" {
      providers."llama.cpp" = {
        baseUrl = "http://127.0.0.1:8080";
        api = "openai-responses";
        auth = "none";
        discovery.type = "llama.cpp";
        modelOverrides."qwen3.8-27b" = {
          name = "Qwen 3.8 27B Q4_K_P (local)";
          tokenizer = "qwen3";
          maxTokens = 32768;
        };
      };
    };

    # Drives the FreeCAD MCP server; needs FreeCAD (snap) and niri-agent.
    ".omp/agent/skills/freecad-design".source = freecadSkill;
  };

  home.activation.ompMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mcp="$HOME/.omp/agent/mcp.json"
    run mkdir -p "$(dirname "$mcp")"
    tmp=$(mktemp)
    if { [ -s "$mcp" ] && cat "$mcp" || echo '{}'; } \
      | ${lib.getExe pkgs.jq} --slurpfile nix ${mcpServers} '. * $nix[0]' > "$tmp"; then
      run cp "$tmp" "$mcp"
    fi
    rm -f "$tmp"
  '';
}
