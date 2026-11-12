{ lib, pkgs, ... }:
{
  # Carapace registers `_carapace_completer` via compdef for every command it
  # has a spec for; everything else keeps zsh's native completion. Results go
  # through compsys, so fzf-tab (zsh.nix) renders them like any other match.
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  # Commands carapace has no spec for, completed through their own completion
  # framework. Each entry is also compdef'd to carapace. lxc is cobra-based, so
  # this calls `lxc __complete` directly; no shell completion script needed.
  xdg.configFile."carapace/bridges.yaml".source = (pkgs.formats.yaml { }).generate "bridges.yaml" {
    lxc = "cobra";
  };

  # Runs after compinit (570) and fzf-tab (900), before carapace (1000).
  programs.zsh.initContent = lib.mkOrder 950 ''
    # fzf-tab: a plain descriptions format enables group headers/switching for
    # carapace's tagged groups; escape sequences here are ignored by fzf-tab.
    zstyle ':completion:*:descriptions' format '[%d]'
    # Let fzf-tab handle selection instead of zsh's own menu.
    zstyle ':completion:*' menu no
    # Carapace adds matches as full values (`modules/cli/`) but displays only
    # the last segment (`cli/`), without telling compsys about the shared
    # prefix. fzf-tab's default `input` query is then the typed `modules/`,
    # which matches no display string and empties the menu. Seed the query
    # from the displays' common prefix only, which always matches every
    # candidate. https://github.com/Aloxaf/fzf-tab/issues/32#issuecomment-1519639800
    zstyle ':fzf-tab:*' query-string prefix
  '';
}
