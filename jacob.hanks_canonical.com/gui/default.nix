{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}:
{
  imports = [
    ./kitty.nix
    #./hypr.nix
    ./firefox.nix
  ]
  ++ lib.optionals isNixOS [
    ./gnome.nix
    ./style.nix
  ];

  home.packages = lib.mkIf config.system.gui.enable (
    with pkgs;
    [
      obsidian
    ]
  );
}
