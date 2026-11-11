{
  imports = [
    ../../modules/home.nix
    ./kitty.nix
    ./nushell.nix
    ./omp.nix
  ];

  home = {
    username = "anderson";
    sessionPath = [
      "$HOME/.local/bin"
    ];
  };

  programs = {
    git = {
      enable = true;
      settings.user = {
        name = "quanchobi";
        email = "quanchobi@proton.me";
      };
    };

    zsh = {
      initExtra = ''
        export PATH="$PATH:$HOME/.local/bin"
      '';
      sessionVariables = {
        "DEBFULLNAME" = "Jacob Hanks";
        "DEBEMAIL" = "jacob.hanks@canonical.com";
      };
    };

    starship.settings = {
      right_format = "$username$hostname$localip$shlvl$singulariy$kubernetes$directory$vcsh$fossil_branch$git_branch$git_commit$git_state$git_metrics$git_status$hg_branch$pijul_channel$docker_context$package$c$cmake$cobol$daml$dart$deno$dotnet$elixir$elm$erlang$fennel$golang$guix_shell$haskell$haxe$helm$java$julia$kotlin$gradle$lua$nim$nodejs$ocaml$opa$perl$php$pulumi$purescript$python$raku$rlang$red$ruby$rust$scala$solidity$swift$terraform$vlang$vagrant$zig$buf$nix_shell$conda$meson$spack$memory_usage$aws$gcloud$openstack$azure$env_var$crystal$custom$sudo$cmd_duration$line_break$jobs$battery$time$status$container$shell";
      directory.read_only = "󰌾 ";
    };
  };
}
