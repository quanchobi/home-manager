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
    initExtra = ''
      export PATH="$PATH:$HOME/.local/bin"
    '';
    profileExtra = "";
    envExtra = "";
    sessionVariables = {
      "DEBFULLNAME" = "Jacob Hanks";
      "DEBEMAIL" = "jacob.hanks@canonical.com";
    };
    shellAliases = { };
  };
}
