{
  programs.git = {
    enable = true;
    userName = "Jacob Hanks";
    userEmail = "jacob.hanks@canonical.com";
    extraConfig = {
      init.defaultBranch = "main";
      gitreview.username = "quanchobi";
    };
  };
}
