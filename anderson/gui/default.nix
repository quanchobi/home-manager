{
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}:
{
  imports = [
  ]
  ++ lib.optionals isNixOS [
    ./kitty.nix
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
