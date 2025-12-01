{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [ ];

  options = { };

  config = lib.mkIf config.system.gui.enable {
    programs.obs-studio = {
      enable = true;
      plugins = [ pkgs.obs-studio-plugins.wlrobs ];
    };
  };
}
