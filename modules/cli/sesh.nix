{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Everything sesh shells out to: the tmux server's PATH (inherited by
  # run-shell) doesn't include the Home Manager profile.
  seshInputs = [
    config.programs.sesh.package
    config.programs.tmux.package
    config.programs.zoxide.package
    pkgs.coreutils
    pkgs.git
  ];

  # `sesh list --icons [flags]`, minus directory entries that already have a
  # session there (sesh's --hide-duplicates would also hide a second session
  # in the same directory), with every other session whose agents need
  # attention painted in its window-title colours (yellow for needs-input, red
  # for done, unless configured otherwise).
  # SESH_PICK_CURRENT names the session to leave uncoloured.
  seshList = pkgs.writeShellApplication {
    name = "sesh-list";
    runtimeInputs = seshInputs;
    text = ''
      # tmux colour (name, brightname, colourN, #rrggbb) -> SGR parameters.
      # $1 is 38 (fg) or 48 (bg); prints nothing for default/unknown colours.
      sgr() {
        local base=$1 colour=''${2,,} bright=0 n
        if [[ $colour == bright* ]]; then
          bright=60
          colour=''${colour#bright}
        fi
        case $colour in
        black) n=0 ;;
        red) n=1 ;;
        green) n=2 ;;
        yellow) n=3 ;;
        blue) n=4 ;;
        magenta) n=5 ;;
        cyan) n=6 ;;
        white) n=7 ;;
        colour* | color*)
          echo "$base;5;''${colour##*r}"
          return
          ;;
        \#??????)
          echo "$base;2;$((16#''${colour:1:2}));$((16#''${colour:3:2}));$((16#''${colour:5:2}))"
          return
          ;;
        *) return ;;
        esac
        echo "$((base - 8 + bright + n))"
      }

      current=''${SESH_PICK_CURRENT:-$(tmux display-message -p '#S' 2>/dev/null || true)}
      declare -A style=()
      while IFS=$'\t' read -r session _ bg fg; do
        style[$session]="$(sgr 48 "$bg");$(sgr 38 "$fg")"
        style[$session]=''${style[$session]#;}
        style[$session]=''${style[$session]%;}
      done < <(${config.programs.tmux.agentIndicator.dir}/scripts/session-attention.sh --exclude "$current")

      declare -A session_name=() session_path=()
      while IFS=$'\t' read -r name path; do
        session_name[$name]=1
        session_path[$path]=1
      done < <(tmux list-sessions -F $'#{session_name}\t#{session_path}' 2>/dev/null || true)

      sesh list --icons "$@" | while IFS= read -r line; do
        name=''${line#* }
        if [[ -z ''${session_name[$name]:-} && -n ''${session_path[''${name/#\~/$HOME}]:-} ]]; then
          continue
        fi
        if [[ -n ''${style[$name]:-} ]]; then
          printf '%s \e[%sm%s\e[0m\n' "''${line%% *}" "''${style[$name]}" "$name"
        else
          printf '%s\n' "$line"
        fi
      done
    '';
  };

  # fzf picker behind both prefix+s and the `s` alias. Replaces the module's
  # built-in binding to change how directories are named: a directory opens as
  # a session named after its git repository (rooted at the repo top level), or
  # after the directory itself outside a repo, never `repo/sub/dir`.
  # $1: the current session (tmux expands '#S' in the binding).
  seshPick = pkgs.writeShellApplication {
    name = "sesh-pick";
    runtimeInputs = seshInputs ++ [
      pkgs.fd
      pkgs.fzf
    ];
    text = ''
      SESH_PICK_CURRENT=''${1:-$(tmux display-message -p '#S' 2>/dev/null || true)}
      export SESH_PICK_CURRENT
      list=${lib.getExe seshList}
      # Prompts match the shell's ❯; filtered views prefix the icon sesh uses
      # for that source (tmux, config, zoxide) or a search glyph for ^f.
      selection=$(
        "$list" | fzf --tmux 80%,70% \
          --no-sort --ansi --border-label ' sesh ' --prompt '❯ ' \
          --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind "ctrl-a:change-prompt(❯ )+reload($list)" \
          --bind "ctrl-t:change-prompt( ❯ )+reload($list -t)" \
          --bind "ctrl-g:change-prompt( ❯ )+reload($list -c)" \
          --bind "ctrl-x:change-prompt( ❯ )+reload($list -z)" \
          --bind 'ctrl-f:change-prompt( ❯ )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind "ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(❯ )+reload($list)" \
          --preview-window 'right:55%' \
          --preview 'sesh preview {}'
      ) || exit 0

      # sesh lines are "<icon> <name>"; ^f (fd) lines are bare absolute paths.
      case $selection in
      /*) target=$selection ;;
      *) target=''${selection#* } ;;
      esac
      target=''${target/#\~/$HOME}

      if ! tmux has-session -t "=$target" 2>/dev/null && [[ -d $target ]]; then
        target=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || realpath "$target")
      fi
      exec sesh connect "$target"
    '';
  };
in
{
  programs.sesh = {
    enable = true;
    enableAlias = false;
    enableTmuxIntegration = false;
  };

  home.shellAliases.s = lib.getExe seshPick;

  programs.tmux.extraConfig = ''
    bind-key s run-shell "${lib.getExe seshPick} '#S'"
  '';
}
