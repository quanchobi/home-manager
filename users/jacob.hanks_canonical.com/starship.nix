{
  programs.starship.settings = {
    right_format = "$username$hostname$localip$shlvl$singulariy$kubernetes\${custom.path}$vcsh$fossil_branch$git_branch$git_commit$git_state$git_metrics$git_status$hg_branch$pijul_channel$docker_context$package$c$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa$perl$php$pulumi$purescript$python$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$vlang$vagrant$zig$buf$nix_shell$conda$meson$spack$memory_usage$aws$gcloud$openstack$azure$env_var$crystal$custom$sudo$cmd_duration$line_break$jobs$battery$time$status$container$shell";

    # Replaces `directory`: inside a git repo, show the path from the repo
    # root (`/path/to/git/repo` -> `git/repo`); elsewhere, fish-style
    # abbreviate every parent (`/path/to/foo/bar/baz` -> `/p/t/f/b/baz`).
    # The native module can't do both: one `truncation_length` drives fish
    # abbreviation and the repo-root fallback.
    custom.path = {
      when = true;
      shell = [ "sh" ];
      style = "bold cyan";
      format = "[$output]($style) ";
      command = ''
        if top=$(git rev-parse --show-toplevel 2>/dev/null); then
          prefix=$(git rev-parse --show-prefix)
          p="''${top##*/}/''${prefix%/}"
          p=''${p%/}
        else
          p=$PWD
          case $p in "$HOME") p="~" ;; "$HOME"/*) p="~''${p#"$HOME"}" ;; esac
          p=$(printf '%s\n' "$p" | awk -F/ -v OFS=/ '{ for (i = 1; i < NF; i++) $i = substr($i, 1, ($i ~ /^\./) ? 2 : 1); print }')
        fi
        [ -w . ] || p="$p 󰌾"
        printf '%s\n' "$p"
      '';
    };
  };
}
