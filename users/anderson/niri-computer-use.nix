# niri-computer-use (github.com/quanchobi/niri-computer-use, the fork with
# background desktops): the CLI, its MCP server for omp, the skill that drives
# it, and the policy file. Agents get a background desktop, a nested niri on a
# workspace of its own, so they never touch the live desktop.
#
# niri's config (not managed here) must end with `include "niri-computer-use.kdl"`
# and should bind the stop key to ~/.nix-profile/bin/niri-computer-use stop.
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  unwrapped = inputs.niri-computer-use.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # The server takes grim from PATH, and Ubuntu's grim is built without the JPEG
  # support screenshots need, so Nix's goes first.
  ncu = pkgs.symlinkJoin {
    name = "niri-computer-use";
    paths = [ unwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/niri-computer-use --prefix PATH : ${lib.getBin pkgs.grim}/bin";
    inherit (unwrapped) meta;
  };
in
{
  # `status`, `stop`, `resume` and `recover` for the user and the stop key.
  home.packages = [ ncu ];

  home.file.".omp/agent/skills/niri-computer-use".source =
    "${ncu}/share/niri-computer-use/skills/niri-computer-use";

  # Read once per server start: restart the omp session after a switch.
  xdg.configFile."niri-computer-use/policy.toml".source =
    (pkgs.formats.toml { }).generate "niri-computer-use-policy.toml"
      {
        unrestricted = true;
        # The host bus: snap FreeCAD exits at once on a private one, since snapd
        # cannot create its systemd scope there.
        background = {
          bus = "host";
          width = 1600;
          height = 1000;
        };

        # freecad-design starts FreeCAD in the background desktop with this.
        # app_id is what `launch` waits for; a wrong one still starts the app
        # but reports `observed: none`.
        preset = [
          {
            name = "freecad";
            argv = [ "/snap/bin/freecad" ];
            app_id = "FreeCAD";
          }
          {
            # Qt's setDesktopFileName in src/lichii/main.cpp sets the app_id.
            name = "lichii";
            argv = [ "/home/anderson/.local/bin/lichii-linux-x86_64.AppImage" ];
            app_id = "io.github.zortos293.lichii";
          }
          {
            name = "blender";
            argv = [ "/snap/bin/blender" ];
            app_id = "blender";
          }
          {
            # The policy allows `flatpak run` of an app, but not `--command`.
            name = "orca-slicer";
            argv = [
              "/usr/bin/flatpak"
              "run"
              "com.orcaslicer.OrcaSlicer"
            ];
            app_id = "com.orcaslicer.OrcaSlicer";
          }
        ];
      };

  omp.mcpServers.niri-computer-use = {
    type = "stdio";
    command = lib.getExe ncu;
    args = [ "serve" ];
  };
}
