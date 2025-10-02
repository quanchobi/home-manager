{ pkgs, config, ... }:
{
  imports = [ ];

  options = { };

  config = {
    programs.obs-studio = {
      inherit (config.system.gui) enable;
      plugins = [ pkgs.obs-studio-plugins.wlrobs ];
    };
  };
}
