# Only for standalone home-manager on a non-NixOS distro (imported by mkHome).
# On NixOS the system owns these concerns.
{
  # Unfree fonts; mkHome allows unfree.
  imports = [ ./fonts.nix ];

  # XDG_DATA_DIRS, TERMINFO_DIRS, nix.sh sourcing and distro zsh fpaths, so
  # Nix-installed programs integrate with the host distro.
  targets.genericLinux = {
    enable = true;
    # No GUI apps come from Nix, so skip the Mesa driver closure and the
    # `sudo non-nixos-gpu-setup` nag on every switch.
    gpu.enable = false;
  };

  # Weekly systemd user timer. Deleting old profile generations (home-manager
  # ones included) is what lets their store paths be collected.
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}
