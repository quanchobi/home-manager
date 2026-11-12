{ pkgs, ... }:
{
  imports = [
    ./atuin.nix
    ./carapace.nix
    ./direnv.nix
    ./eza.nix
    ./git.nix
    ./starship.nix
    ./tmux.nix
    ./zoxide.nix
    ./zsh.nix
    ./sesh.nix
    ./fzf.nix
  ];

  home.packages = with pkgs; [
    # Fonts
    aegyptus
    nerd-fonts.intone-mono
    symbola
  ];
}
