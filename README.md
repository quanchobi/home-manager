# My Home Manager Configuration

## 🏡 Overview

This is my home-manager configuration. There are many like it, but this one is mine. This _is now_ spun into its own flake such that I can use it on other non NixOS machines.

## 📁 Organization

Files are organized like this:

```
.
├─── flake.nix          # mkHome helper, homeConfigurations, nixosModules.default
├─── modules            # shared by every user
│   ├─── home.nix       # base: stylix, options, cli, gui, stateVersion
│   ├─── options.nix
│   ├─── accounts       # WIP, not imported yet
│   ├─── cli
│   │   ├─── default.nix
│   │   ╰─── <cli modules>
│   ╰─── gui
│       ├─── default.nix
│       ╰─── <gui modules>
╰─── users
    ╰─── <user>
        ├─── default.nix  # entry point: imports modules/home.nix, sets username
        ╰─── <overrides>  # only what differs from modules/
```

A user's `default.nix` holds just that user's differences (identity, git, shell
tweaks, extra modules); everything else comes from `modules/`. Adding a user is
a new `users/<user>/default.nix` plus one `mkHome "<user>"` line in `flake.nix`.

### ⌨️ CLI

CLI modules are enabled for all machines. It provides a basic set of CLI tools that are useful to have on any system.

### 💻 GUI

Some GUI modules (GNOME, stylix, kitty) are only enabled on NixOS. This is done with the `isNixOS` special arg, set in `flake.nix` (`false` for `homeConfigurations`, `true` for `nixosModules.default`).

```{nix}
{ lib, isNixOS, ... }:
{
  imports = [
    ./kitty.nix
  ]
  ++ lib.optionals isNixOS [
    ./gnome.nix
    ./style.nix
  ];
}
```

## 📝 Notes

**_HERE BE DRAGONS!_**

Use at your own peril. If you want to use on a non NixOS system, you should probably not use most of the GUI modules.
