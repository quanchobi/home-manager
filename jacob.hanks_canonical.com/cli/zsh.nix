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
    completionInit = ''
      autoload -Uz compinit && compinit
      autoload -Uz bashcompinit && bashcompinit
    '';
    syntaxHighlighting = {
      enable = true;
      styles = { };
    };
    history = {
      append = true;
    };
    sessionVariables = { };
    shellAliases = { };
  };
}
