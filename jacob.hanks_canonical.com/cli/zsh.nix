{ pkgs, ... }:
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
    shellAliases = { };
    plugins = [
      {
        name = "vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];
  };
}
