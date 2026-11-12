{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/home.nix
  ];

  home = {
    username = "jacob.hanks@canonical.com";
    sessionPath = [
      "${config.home.homeDirectory}/.bin/bin"
    ];
    packages = [ pkgs.rustup ];
  };

  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "Jacob Hanks";
        user.email = "jacob.hanks@canonical.com";
        gitreview.username = "quanchobi";
        core.editor = "nvim";
        gitubuntu.lpuser = "quanchobi";
        sendemail = {
          smtpserver = "smtp.gmail.com";
          smtpuser = "jacob.hanks@canonical.com";
          smtpserverport = "587";
        };
      };
      signing = {
        key = "8696E39D77F41EFDBBFB92B6C3C8E18E2DA10627";
        signByDefault = true;
      };
    };

    zsh = {
      completionInit = ''
        autoload -Uz compinit && compinit
        autoload -Uz bashcompinit && bashcompinit
      '';
      history.expireDuplicatesFirst = true;
      # By default zsh-vi-mode sets its keymaps on the first prompt, wiping the
      # Ctrl-R / up-arrow / Tab bindings from atuin, fzf and fzf-tab. Sourcing
      # mode applies them when the plugin loads, before those integrations.
      localVariables.ZVM_INIT_MODE = "sourcing";
      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];
    };
  };
}
