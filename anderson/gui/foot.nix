{ lib, config, ... }:
{
  imports = [ ];

  options = { };

  config = lib.mkIf config.system.gui.enable {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          term = "xterm-256color";
          font = lib.mkForce "IntoneMono Nerd Font:size=14";
        };

        csd = {
          preferred = "none";
        };

        # Handled by stylix
        colors = {
          background = lib.mkForce "1c2023";
        };
      };
    };
  };
}
