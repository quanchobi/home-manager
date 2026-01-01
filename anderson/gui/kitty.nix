{ pkgs, lib, ... }:
{
  programs.kitty = {
    enable = true;
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
      font_size = "12.0";

      # Special Colors
      foreground = "#9a9fa6"; # base05
      background = "#212121"; # base00
      cursor = "#9a9fa6"; # base05
      selection_background = "#9a9fa6"; # base05
      selection_foreground = "#212121"; # base00

      # The 16 Terminal Colors
      # black
      color0 = "#212121"; # base00
      color8 = "#6c6d70"; # base03

      # red
      color1 = "#b14956"; # base08
      color9 = "#ec5f67"; # base12

      # green
      color2 = "#91b377"; # base0B
      color10 = "#88e985"; # base14

      # yellow
      color3 = "#5485c0"; # base0A
      color11 = "#fdc253"; # base13

      # blue
      color4 = "#7b8fa4"; # base0D
      color12 = "#5485c0"; # base16

      # magenta
      color5 = "#a5779e"; # base0E
      color13 = "#bf83c0"; # base17

      # cyan
      color6 = "#7fcccb"; # base0C
      color14 = "#58c2c0"; # base15

      # white
      color7 = "#9a9fa6"; # base05
      color15 = "#ffffff"; # base07
    };
  };
}
