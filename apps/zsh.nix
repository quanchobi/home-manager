{
    programs.zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableCompletion = true;
        syntaxHighlighting = {
            enable = true;
            styles = { };
        };
        initExtra = ''
            autoload -U bashcompinit
            bashcompinit

            # Autostart zsh
            if [ -z "$TMUX" ]; then
                tmux attach -d || tmux new
            fi

            eval "$(register-python-argcomplete pipx)"
        '';
        profileExtra = ''
            # Nix
                if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
                  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
                fi
            # End Nix
        '';
        envExtra = ''
            . "$HOME/.cargo/env"
        '';
        sessionVariables = { };
        shellAliases = { };
    };
}
