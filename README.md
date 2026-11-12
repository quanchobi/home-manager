# My Home Manager Configuration

## 🏡 Overview

This is my home-manager configuration. There are many like it, but this one is mine. This _is now_ spun into its own flake such that I can use it on other non NixOS machines.

## 📁 Organization

Files are organized like this:

```
.
├─── flake.nix            # mkHome helper, homeConfigurations, nixosModules.default
├─── modules              # shared by every user
│   ├─── home.nix         # base: cli, stateVersion
│   ├─── standalone.nix   # non-NixOS only: genericLinux target, nix gc
│   ├─── accounts         # WIP, not imported yet
│   ╰─── cli
│       ├─── default.nix
│       ╰─── <cli modules>
╰─── users
    ╰─── <user>
        ├─── default.nix  # entry point: imports modules/home.nix, sets username
        ├─── <host>.nix   # optional per-host additions (e.g. anderson/desktop.nix)
        ╰─── <overrides>  # only what differs from modules/
```

A user's `default.nix` holds just that user's differences (identity, git, shell
tweaks, extra modules); everything else comes from `modules/`. Adding a user is
a new `users/<user>/default.nix` plus one `mkHome "<system>" [ ./users/<user> ]`
line in `flake.nix`. Host-specific config is a `"<user>@<hostname>"` entry that
adds that host's module; `home-manager switch --flake .` prefers it over
`<user>` when the hostname matches.

### ⌨️ CLI

CLI modules are enabled for all machines. They configure the core shell
environment: zsh, starship, tmux/sesh, fzf, carapace, eza, zoxide (as `cd`),
atuin, direnv and git. One-off utilities that need no configuration are left to
the host's package manager.

### 🔑 SSH

`users/anderson/ssh.nix` manages SSH defaults only. Host blocks live in an
untracked `~/.ssh/hosts`, which the generated `~/.ssh/config` includes, so
hostnames and addresses stay out of this public repo.

## 📝 Notes

**_HERE BE DRAGONS!_**

Use at your own peril.
