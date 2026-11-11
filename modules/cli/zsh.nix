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
    syntaxHighlighting.enable = true;
    history.append = true;
  };
}
