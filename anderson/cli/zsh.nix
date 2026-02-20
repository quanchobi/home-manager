{
  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "completion"
      ];
    };
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
      styles = { };
    };
    history = {
      append = true;
    };
    initContent = "";
    profileExtra = "";
    envExtra = "";
    sessionVariables = { };
    shellAliases = { };
  };
}
