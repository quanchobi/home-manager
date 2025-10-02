{
  inputs,
  pkgs,
  lib,
  config,
  systemGuiEnable ? true,
  ...
}:
{
  imports = lib.optionals systemGuiEnable [
    ./foot.nix
    ./gnome.nix
    ./obs.nix
    ./style.nix
  ];

  config = lib.mkIf config.system.gui.enable {
    home.packages = with pkgs; [
      adwaita-icon-theme
      celluloid
      freecad-wayland
      inputs.zen-browser.packages."${system}".default
      kdePackages.okular
      love
      obsidian
      prismlauncher
      ryujinx
      vesktop
      wl-clipboard
      zoom-us
    ];
  };
}
