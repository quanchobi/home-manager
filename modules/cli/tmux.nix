_: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    disableConfirmationPrompt = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    prefix = "C-Space";
    terminal = "xterm-256color";
    extraConfig = ''
      # exec zsh at the start
        set -g default-shell /bin/zsh
        set -g renumber-windows on
      # Change splits to | and - as opposed to " and %
        unbind '"'
        unbind %
        bind | split-window -h
        bind - split-window -v
      # Theming
      # Colors reference the terminal's palette (default/colourN), not hex, so tmux
      # follows the DankMaterialShell-generated ghostty/kitty theme when it changes.
      # default = background/foreground, colour0 = bg, colour4 = accent,
      # colour5 = selection, colour6 = primary, colour8 = outline.
        set-option -g status-position "top" # put status at top instead of bottom, since that is where nvim goes

        # Status Bar
        set -g status-style 'fg=default,bg=default'
        set -g status-left "#[fg=colour4]   #S   "
        set -g status-right "#[fg=colour4]%a %Y-%m-%d 󱑒 %H:%M %p "

        # Windows (active mirrors the kitty tab bar: dark text on primary)
        set -g window-status-format ' #I #W '
        set -g window-status-current-format ' *#I #W '
        set -g window-status-style 'fg=default,bg=default'
        set -g window-status-current-style 'fg=colour0,bg=colour6,bold'
        set -g window-status-last-style 'fg=colour6,bg=default'

        # Message / Command Prompt
        set -g message-style 'fg=colour6,bg=default'
        set -g message-command-style 'fg=colour6,bg=default'

        # Copy mode / selection (matches terminal selection colors)
        set -g mode-style 'fg=default,bg=colour5'

        # Panes
        set -g pane-active-border-style 'fg=colour6,bg=default'
        set -g pane-border-style 'fg=colour8,bg=default'

        # Clock mode
        set -g clock-mode-colour colour6
    '';
  };
}
