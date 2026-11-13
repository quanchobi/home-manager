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
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 950 ''
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
    '')

    # Runs after carapace (1000) has defined `_carapace_completer`.
    # Carapace escapes its values for _describe's `match:description` syntax
    # (`\` -> `\\`, `:` -> `\:`) on top of shell quoting, and passes them as
    # _describe's second array. _describe only strips that extra layer from
    # the second array on its grouped path (verbose and list-grouped on);
    # otherwise it reaches the command line, so `a b` completes to `a\\ b`.
    # fzf-tab turns list-grouped off while completing, so every carapace
    # completion took that path. Route carapace's _describe call through a
    # wrapper that strips the layer whenever _describe won't.
    # https://github.com/Aloxaf/fzf-tab/issues/503
    (lib.mkOrder 1010 ''
      _carapace_describe() {
        # Called as `-t tag tag displaysArr valuesArr ...`; $5 names the
        # caller's local values array, rewritten in place.
        setopt localoptions extendedglob
        zstyle -T ":completion:''${curcontext}:$2" verbose &&
          zstyle -T ":completion:''${curcontext}:$2" list-grouped ||
          set -A "$5" "''${(@)''${(@P)5}//\\(#b)(?)/$match[1]}"
        _describe "$@"
      }
      if [[ $functions[_carapace_completer] == *'&& _describe -t "''${tag}"'* ]]; then
        functions[_carapace_completer]=''${functions[_carapace_completer]/'&& _describe -t'/&& _carapace_describe -t}
      else
        print -u2 "carapace.nix: _carapace_completer no longer matches; completions may be double-escaped"
      fi
    '')
  ];
}
