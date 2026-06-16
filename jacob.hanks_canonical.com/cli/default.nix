{ pkgs, ... }:
{
  imports = [
    ./eza.nix
    ./git.nix
    ./password-store.nix
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
    ./opencode.nix
    ./sesh.nix
    ./fzf.nix
  ];

  home.packages = with pkgs; [
    # Utilities
    btop
    netcat-gnu
    unzip
    rustup

    # Fonts
    aegyptus
    nerd-fonts.intone-mono
    symbola
  ];
}
