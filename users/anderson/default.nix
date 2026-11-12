{
  imports = [
    ../../modules/home.nix
    ./kitty.nix
    ./omp.nix
  ];

  home = {
    username = "anderson";
    sessionPath = [
      "$HOME/.local/bin"
    ];
  };

  programs = {
    git = {
      enable = true;
      settings.user = {
        name = "quanchobi";
        email = "quanchobi@proton.me";
      };
    };

    zsh = {
      initExtra = ''
        export PATH="$PATH:$HOME/.local/bin"
      '';
      sessionVariables = {
        "DEBFULLNAME" = "Jacob Hanks";
        "DEBEMAIL" = "jacob.hanks@canonical.com";
      };
    };
  };
}
