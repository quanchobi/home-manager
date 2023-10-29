{
    programs.zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableCompletion = true;
        initExtra = ''
            autoload -U bashcompinit
            bashcompinit

            eval "$(register-python-argcomplete pipx)"
        '';
        profileExtra = ''
            # Nix
                if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
                  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
                fi
            # End Nix
        '';
        sessionVariables = { };
        shellAliases = { };
        syntaxHighlighting = {
            enable = true;
            styles = { };
        };
    };
}
