{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/home.nix
    ./opencode.nix
    #./hypr.nix
    ./firefox.nix
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
      enable = false;
      settings = {
        user.name = "Jacob Hanks";
        user.email = "jacob.hanks@canonical.com";
        gitreview.username = "quanchobi";
        core.defaultEditor = "nvim";
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
      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];
    };

    kitty = {
      enableGitIntegration = true;
      actionAliases = {
        "launch_tab" = "launch --cwd=current --type=tab";
        "launch_window" = "launch --cwd=current --type=os-window";
      };
      settings.shell = "zsh --login";
    };
  };
}
