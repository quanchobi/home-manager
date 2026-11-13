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
    # Debian/Ubuntu packaging identity (dch, debuild), for every program.
    sessionVariables = {
      DEBFULLNAME = "Jacob A Hanks";
      DEBEMAIL = "jacob.hanks@canonical.com";
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "quanchobi";
      email = "quanchobi@proton.me";
    };
  };
}
