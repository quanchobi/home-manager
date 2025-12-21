{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
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
      name = "Carbonfox";
      author = "EdenEast";
      license = "MIT";
      blurb = "Carbonfox theme from the neovim colorscheme nightfox.nvim.";
      # upstream = "https://github.com/EdenEast/nightfox.nvim/blob/main/extra/carbonfox/kitty.conf";
      # The basic colors
      foreground = "#f2f4f8";
      background = "#161616";
      selection_foreground = "#f2f4f8";
      selection_background = "#2a2a2a";

      # Cursor colors
      cursor = "#f2f4f8";
      cursor_text_color = "#161616";

      # URL underline color when hovering with mouse
      url_color = "#25be6a";

      # kitty window border colors and terminal bell colors
      active_border_color = "#78a9ff";
      inactive_border_color = "#535353";
      bell_border_color = "#3ddbd9";
      # visual_bell_color = "none"; # Commented out as it's not a color

      # Tab bar colors
      active_tab_foreground = "#0c0c0c";
      active_tab_background = "#78a9ff";
      inactive_tab_foreground = "#6e6f70";
      inactive_tab_background = "#2a2a2a";
      # tab_bar_background = "none"; # Commented out as it's not a color
      # tab_bar_margin_color = "none"; # Commented out as it's not a color

      # The basic 16 colors
      color0 = "#282828"; # black
      color8 = "#484848"; # bright black
      color1 = "#ee5396"; # red
      color9 = "#f16da6"; # bright red
      color2 = "#25be6a"; # green
      color10 = "#46c880"; # bright green
      color3 = "#ebcb8b"; # yellow
      color11 = "#f0d399"; # bright yellow
      color4 = "#78a9ff"; # blue
      color12 = "#8cb6ff"; # bright blue
      color5 = "#be95ff"; # magenta
      color13 = "#c8a5ff"; # bright magenta
      color6 = "#33b1ff"; # cyan
      color14 = "#52bdff"; # bright cyan
      color7 = "#dfdfe0"; # white
      color15 = "#e4e4e5"; # bright white

      # The remaining colors (color16 and color17)
      color16 = "#3ddbd9";
      color17 = "#ff7eb6";
    };
  };
}
