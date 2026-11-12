{
  config,
  lib,
  ...
}:
let
  agentIndicatorDir = config.programs.tmux.agentIndicator.dir;
in
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    disableConfirmationPrompt = true;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    prefix = "C-Space";
    # Home Manager's zsh, not the distro's /bin/zsh.
    shell = lib.getExe config.programs.zsh.package;
    # tmux's default 500ms wait to tell Esc from Alt-<key> delays Esc in nvim.
    escapeTime = 10;
    focusEvents = true;
    historyLimit = 50000;
    terminal = "tmux-256color";
    agentIndicator = {
      enable = true;
      # omp added to the default process list so its icon shows even before a
      # hook fires. Notifications (display-message popups) are off; the
      # window-title colors already signal needs-input/done. Icons are nerd
      # font robots (md-robot_*_outline): plain for every agent, happy while
      # running, confused when it needs input, plain again when done.
      settings = {
        processes = "claude,codex,aider,cursor,opencode,omp";
        notification-enabled = false;
        icons = "default=󱙺";
        state-icons = "running=󱜚,needs-input=󱚠,done=󱙺";
      };
      # The plugin expands #{agent_indicator} when it loads, so status-right
      # must be set here: programs.tmux.extraConfig is emitted after plugins.
      extraConfig = ''
        set -g status-right "#{agent_indicator} #[fg=colour4]%a %Y-%m-%d 󱑒 %H:%M "
      '';
      integrations = {
        claude.enable = true;
        omp.enable = true;
      };
    };
    extraConfig = ''
      # Pass truecolor through to the outer terminal
        set -as terminal-features ",*:RGB"
        set -g renumber-windows on
      # Change splits to | and - as opposed to " and %
        unbind '"'
        unbind %
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
      # Theming
      # Colors reference the terminal's palette (default/colourN), not hex, so tmux
      # follows the DankMaterialShell-generated ghostty/kitty theme when it changes.
      # default = background/foreground, colour0 = bg, colour4 = accent,
      # colour5 = selection, colour6 = primary, colour8 = outline.
        set-option -g status-position "top" # put status at top instead of bottom, since that is where nvim goes

        # Status Bar (status-right is set with the agent-indicator plugin above)
        set -g status-style 'fg=default,bg=default'
        # The gem takes the window-title colour of the most urgent agent state
        # (needs-input, then done) in any other session; accent otherwise.
        set -g status-left-length 50
        set -g status-left "#[fg=#(${agentIndicatorDir}/scripts/session-attention.sh --exclude '#S' --color colour4)]   #[fg=colour4]#S   "

        # Windows (active mirrors the kitty tab bar: dark text on primary)
        set -g window-status-format ' #I #W '
        set -g window-status-current-format ' *#I #W '
        set -g window-status-style 'fg=color6,bg=default'
        set -g window-status-current-style 'fg=colour0,bg=colour6,bold'
        # last/bell styles are layered over window-status-style and would hide
        # tmux-agent-indicator's per-window title colours, so both are disabled.
        set -g window-status-last-style 'default'
        set -g window-status-bell-style 'default'

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
