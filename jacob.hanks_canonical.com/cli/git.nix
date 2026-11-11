{
  programs = {
    git = {
      enable = false;
      settings = {
        user.name = "Jacob Hanks";
        user.email = "jacob.hanks@canonical.com";
        init.defaultBranch = "main";
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
  };
}
