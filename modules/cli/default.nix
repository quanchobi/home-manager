{ pkgs, ... }:
{
  imports = [
    ./carapace.nix
    ./eza.nix
    ./git.nix
    ./password-store.nix
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
    ./sesh.nix
    ./fzf.nix
  ];

  home.packages = with pkgs; [
    # Utilities
    btop
    netcat-gnu
    unzip

    # Fonts
    aegyptus
    nerd-fonts.intone-mono
    symbola
  ];
}
