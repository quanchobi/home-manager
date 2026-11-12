{ config, lib, ... }:
{
  # Shell history in SQLite, with Ctrl-R search and the up arrow. Each shell
  # (so each tmux pane) gets its own ATUIN_SESSION.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      # Up arrow walks this pane's history; Ctrl-R searches everything.
      filter_mode_shell_up_key_binding = "session";
      update_check = false;
    };
  };

  # `atuin init zsh` prepends its own strategy to ZSH_AUTOSUGGEST_STRATEGY;
  # put back the one zsh.nix chose (it runs before atuin's init, at 700).
  programs.zsh.initContent = lib.mkOrder 1050 ''
    ZSH_AUTOSUGGEST_STRATEGY=(${lib.concatStringsSep " " config.programs.zsh.autosuggestion.strategy})
  '';
}
