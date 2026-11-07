{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "quanchobi";
        email = "quanchobi@proton.me";
      };
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
