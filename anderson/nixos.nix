{
  # This NixOS module bridges the existing home-manager configuration.
  home-manager.users.anderson = {
    imports = [ ./home.nix ];
  };
}
