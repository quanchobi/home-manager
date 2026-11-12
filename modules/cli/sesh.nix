{
  config,
  lib,
  pkgs,
  ...
}:
let
  # fzf picker behind both prefix+s and the `s` alias. Replaces the module's
  # built-in binding to change how directories are named: a directory opens as
  # a session named after its git repository (rooted at the repo top level), or
  # after the directory itself outside a repo, never `repo/sub/dir`.
  seshPick = pkgs.writeShellApplication {
    name = "sesh-pick";
    # Everything sesh shells out to: the tmux server's PATH (inherited by
    # run-shell) doesn't include the Home Manager profile.
    runtimeInputs = [
      config.programs.sesh.package
      config.programs.tmux.package
      config.programs.zoxide.package
      pkgs.coreutils
      pkgs.fd
      pkgs.fzf
      pkgs.git
    ];
    text = ''
      list='sesh list --icons --hide-duplicates'
      selection=$(
        sesh list --icons --hide-duplicates | fzf --tmux 80%,70% \
          --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
          --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
          --bind 'tab:down,btab:up' \
          --bind "ctrl-a:change-prompt(⚡  )+reload($list)" \
          --bind "ctrl-t:change-prompt(🪟  )+reload($list -t)" \
          --bind "ctrl-g:change-prompt(⚙️  )+reload($list -c)" \
          --bind "ctrl-x:change-prompt(📁  )+reload($list -z)" \
          --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
          --bind "ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload($list)" \
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
    bind-key s run-shell ${lib.getExe seshPick}
  '';
}
