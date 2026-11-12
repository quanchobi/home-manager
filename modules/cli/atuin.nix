{ config, lib, ... }:
{
  # Shell history in SQLite, searched with Ctrl-R. The up arrow keeps zsh's
  # own history walk.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings.update_check = false;
  };

  # `atuin init zsh` prepends its own strategy to ZSH_AUTOSUGGEST_STRATEGY;
  # put back the one zsh.nix chose (it runs before atuin's init, at 700).
  programs.zsh.initContent = lib.mkOrder 1050 ''
    ZSH_AUTOSUGGEST_STRATEGY=(${lib.concatStringsSep " " config.programs.zsh.autosuggestion.strategy})
  '';
}
