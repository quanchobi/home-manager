{ pkgs, config, ... }:
{
  imports = [ ];

  options = { };

  config = {
    programs.obs-studio = {
      enable = config.system.gui.enable;
      plugins = [ pkgs.obs-studio-plugins.wlrobs ];
    };
  };
}
