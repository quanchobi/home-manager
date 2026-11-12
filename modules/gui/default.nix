{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}:
{
  # Disabled (not NixOS-specific): ./kitty.nix
  imports = lib.optionals isNixOS [
    #./gnome.nix
    #./style.nix
  ];

  home.packages = lib.mkIf config.system.gui.enable (
    with pkgs;
    [
      #obsidian
    ]
  );
}
