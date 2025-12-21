{
  inputs,
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}:
{
  imports = [
    ./kitty.nix
  ]
  ++ lib.optionals isNixOS [
    ./gnome.nix
    ./style.nix
  ];

  home.packages = lib.mkIf config.system.gui.enable (
    with pkgs;
    [
      obsidian
      prismlauncher
    ]
  );
}
