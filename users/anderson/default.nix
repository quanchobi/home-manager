{
  imports = [
    ../../modules/home.nix
    ./omp.nix
    ./ssh.nix
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
      sessionVariables = {
        "DEBFULLNAME" = "Jacob Hanks";
        "DEBEMAIL" = "jacob.hanks@canonical.com";
      };
    };
  };
}
