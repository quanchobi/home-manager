{ inputs, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "completion"
        "history"
      ];
    };
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    history.append = true;
    plugins = [
      {
        name = "fzf-tab";
        src = inputs.fzf-tab;
      }
    ];
  };
}
