{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Fork of accessd/tmux-agent-indicator adding @agent-indicator-state-icons
  # and the omp extension.
  agentIndicator = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "agent-indicator";
    rtpFilePath = "agent-indicator.tmux";
    version = "unstable-${inputs.tmux-agent-indicator.shortRev}";
    src = inputs.tmux-agent-indicator;
  };
  agentIndicatorDir = "${agentIndicator}/share/tmux-plugins/agent-indicator";

  # Upstream's Claude hook template, pointed at the store copy so hooks also
  # resolve outside tmux (where TMUX_AGENT_INDICATOR_DIR is unset).
  claudeHooks = pkgs.writeText "tmux-agent-indicator-claude-hooks.json" (
    builtins.replaceStrings
      [ "\${TMUX_AGENT_INDICATOR_DIR:-$HOME/.tmux/plugins/tmux-agent-indicator}" ]
      [ agentIndicatorDir ]
      (builtins.readFile "${inputs.tmux-agent-indicator}/hooks/claude-hooks.json")
  );
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
    plugins = [
      {
        plugin = agentIndicator;
        # The plugin expands #{agent_indicator} when it loads, so status-right
        # must be set here: programs.tmux.extraConfig is emitted after plugins.
        # omp added to the default process list so its icon shows even before a
        # hook fires. Notifications (display-message popups) are off; the
        # window-title colors already signal needs-input/done. Icons are nerd
        # font robots (md-robot_*_outline): plain for every agent, happy while
        # running, confused when it needs input, plain again when done.
        extraConfig = ''
          set -g status-right "#{agent_indicator} #[fg=colour4]%a %Y-%m-%d 󱑒 %H:%M %p "
          set -g @agent-indicator-processes 'claude,codex,aider,cursor,opencode,omp'
          set -g @agent-indicator-notification-enabled 'off'
          set -g @agent-indicator-icons 'default=󱙺'
          set -g @agent-indicator-state-icons 'running=󱜚,needs-input=󱚠,done=󱙺'
        '';
      }
    ];
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
        set -g status-left "#[fg=colour4]   #S   "

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

  # omp auto-loads extension modules from ~/.omp/agent/extensions. Linked from
  # the plugin package, it calls the scripts beside it.
  home.file.".omp/agent/extensions/tmux-agent-indicator.ts".source =
    "${agentIndicatorDir}/plugins/omp-tmux-agent-indicator.ts";

  # Claude Code rewrites ~/.claude/settings.json itself, so merge the hooks in
  # instead of making it a read-only store symlink. Previous agent-indicator
  # hooks (from older generations) are dropped before the current ones are added.
  home.activation.tmuxAgentIndicatorClaudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    if [ -d "$HOME/.claude" ] && [ ! -L "$settings" ]; then
      tmp=$(mktemp)
      if { [ -s "$settings" ] && cat "$settings" || echo '{}'; } | ${lib.getExe pkgs.jq} --slurpfile tpl ${claudeHooks} '
        def ours: type == "object" and ((.command // "") | type == "string" and test("scripts/agent-state\\.sh .*--agent claude --state"));
        def strip:
          map(if type == "object" and (.hooks | type) == "array" then .hooks |= map(select(ours | not)) else . end)
          | map(select(type != "object" or (.hooks | type) != "array" or (.hooks | length) > 0));
        .hooks = ((.hooks // {}) | map_values(if type == "array" then strip else . end) | with_entries(select(.value != [])))
        | reduce ($tpl[0].hooks | to_entries[]) as $e (.; .hooks[$e.key] += $e.value)
      ' > "$tmp"; then
        run cp "$tmp" "$settings"
      fi
      rm -f "$tmp"
    fi
  '';
}
