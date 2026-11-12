# Fonts for the terminal running on this machine: the nerd font draws the
# starship/tmux glyphs, symbola and aegyptus cover symbols and ancient scripts.
# symbola and aegyptus are unfree, so only standalone.nix imports this (mkHome
# allows unfree); on NixOS the system owns fonts.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    aegyptus
    nerd-fonts.intone-mono
    symbola
  ];
}
