{
  # Loads a directory's .envrc on cd; nix-direnv caches `use flake` shells and
  # keeps them from being garbage collected.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
