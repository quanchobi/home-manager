{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    disableConfirmationPrompt = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    prefix = "C-Space";
    terminal = "xterm-256color";
    plugins = [
      pkgs.tmuxPlugins.tmux-floax
    ];
    extraConfig = ''
      # Change splits to | and - as opposed to " and %
            unbind '"'
            unbind %
            bind | split-window -h
            bind - split-window -v
      # Theming
            set-option -g status-position "top" # put status at top instead of bottom, since that is where nvim goes

      set -g window-status-current-format '#[fg=#a5779e,bg=#15171c] *#I #W'
          # Inactive Window
          set -g window-status-format '#[fg=#6c6d70,bg=#212121] #I #W'
          # Last Active Window
          set -g window-status-last-style 'fg=#ffffff,bg=#1c1c1c'

          # Message / Command Prompt
          set -g message-command-style bg=default,fg=#5485c0
          set -g message-style bg=default,fg=#5485c0

          # Panes
          set -g pane-active-border-style 'fg=#a5779e,bg=default'
          set -g pane-border-style 'fg=#383838,bg=default'

          # Status Bar
          set -g status-style 'bg=#15171c'
          set -g status-left "#[fg=#7b8fa4,bg=#15171c]   #S   "
          set -g status-right "#[fg=#7b8fa4,bg=#15171c]%a %Y-%m-%d 󱑒 %l:%M %p"
    '';
  };
}
