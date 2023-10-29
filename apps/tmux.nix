{
    programs.tmux = {
        enable = true;
        clock24 = true;
        keyMode = "vi";
        customPaneNavigationAndResize = true;
        prefix = "C-Space";
        terminal = "xterm-256color";
        extraConfig = ''
        unbind '"'
        unbind %
        bind | split-window -h
        bind - split-window -v
        '';
    };
}
