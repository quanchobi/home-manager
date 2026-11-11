{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    settings = {
      format = "$os$character";
      # `right_format` (and the path module it uses) is set per user.

      aws.symbol = "  ";

      buf.symbol = " ";

      c.symbol = " ";

      conda.symbol = " ";

      dart.symbol = " ";

      docker_context.symbol = " ";

      elixir.symbol = " ";

      elm.symbol = " ";

      fossil_branch.symbol = " ";

      git_branch.symbol = " ";

      golang.symbol = " ";

      guix_shell.symbol = " ";

      haskell.symbol = " ";

      haxe.symbol = " ";

      hg_branch.symbol = " ";

      hostname.ssh_symbol = " ";

      java.symbol = " ";

      julia.symbol = " ";

      lua.symbol = " ";

      memory_usage.symbol = "󰍛 ";

      meson.symbol = "󰔷 ";

      nim.symbol = "󰆥 ";

      nix_shell.symbol = " ";

      nodejs.symbol = " ";

      os = {
        disabled = false;
        symbols = {
          Alpaquita = " ";
          Alpine = " ";
          Amazon = " ";
          Android = " ";
          Arch = " ";
          Artix = " ";
          CentOS = " ";
          Debian = " ";
          DragonFly = " ";
          Emscripten = " ";
          EndeavourOS = " ";
          Fedora = " ";
          FreeBSD = " ";
          Garuda = "󰛓 ";
          Gentoo = " ";
          HardenedBSD = "󰞌 ";
          Illumos = "󰈸 ";
          Linux = " ";
          Mabox = " ";
          Macos = " ";
          Manjaro = " ";
          Mariner = " ";
          MidnightBSD = " ";
          Mint = " ";
          NetBSD = " ";
          NixOS = " ";
          OpenBSD = "󰈺 ";
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          RedHatEnterprise = " ";
          Redhat = " ";
          Redox = "󰀘 ";
          SUSE = " ";
          Solus = "󰠳 ";
          Ubuntu = " ";
          Unknown = " ";
          Windows = "󰍲 ";
          openSUSE = " ";
        };
      };

      package.symbol = "󰏗 ";

      pijul_channel.symbol = " ";

      python.symbol = " ";

      rlang.symbol = "󰟔 ";

      ruby.symbol = " ";

      rust.symbol = " ";

      scala.symbol = " ";
    };
  };
}
