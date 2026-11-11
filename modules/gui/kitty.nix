{
  pkgs,
  lib,
  isNixOS,
  ...
}:
{
  programs.kitty = {
    # Only managed on NixOS hosts; standalone installs use the system terminal.
    enable = isNixOS;
    font = lib.mkForce {
      package = pkgs.nerd-fonts.intone-mono;
      name = "IntoneMono Nerd Font Mono";
    };

    settings = {
      hide_window_decorations = "yes";
      enable_audio_bell = false;
      disable_ligatures = "never";
      font_family = "IntoneMono Nerd Font Mono";
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
      font_size = "14.0";
    };
  };
}
