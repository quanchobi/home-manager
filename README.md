# home-manager

My [Home Manager](https://github.com/nix-community/home-manager) flake: a zsh/tmux
shell environment and an [oh-my-pi](https://github.com/can1357/oh-my-pi) (omp)
agent setup, shared across standalone non-NixOS machines and NixOS.

Tracks `nixos-26.05` / `release-26.05`. Linux only (`x86_64`, `aarch64`).

## Usage

### Standalone (non-NixOS)

Requires Nix with flakes enabled. First run, before `home-manager` is installed:

```sh
nix run home-manager/release-26.05 -- switch --flake github:quanchobi/home-manager
```

After that, from a checkout:

```sh
home-manager switch --flake .
```

`home-manager` picks `$USER@$(hostname)` if it exists, otherwise `$USER`.

| Configuration               | Adds                                                                 |
| --------------------------- | -------------------------------------------------------------------- |
| `anderson`                  | Personal git identity, SSH defaults                                  |
| `anderson@yappy-yiqi`       | The above, plus desktop omp extras (local models, MCP, CAD)          |
| `jacob.hanks@canonical.com` | Work git identity with signing and `send-email`, rustup, zsh vi-mode |

Every standalone configuration also gets `modules/standalone.nix`:
`targets.genericLinux`, a weekly `nix.gc` that drops generations older than 30
days, and terminal fonts (two of them unfree, which `mkHome` allows).

### NixOS

`nixosModules.default` imports home-manager's NixOS module and configures
`anderson` with the system's `pkgs`. The system must define
`users.users.anderson`. Fonts are left to the system, so no unfree packages are
needed.

```nix
{
  inputs.home = {
    url = "github:quanchobi/home-manager";
    # Only if the system flake also imports home-manager.nixosModules.home-manager:
    # following the same input lets the two imports deduplicate.
    inputs.home-manager.follows = "home-manager";
  };

  # in nixosSystem modules:
  #   inputs.home.nixosModules.default
}
```

## Layout

```
flake.nix               mkHome, homeConfigurations, nixosModules.default, checks
modules/
  home.nix              base for every user: cli, omp, skills, stateVersion
  standalone.nix        non-NixOS only: genericLinux, nix gc, fonts
  fonts.nix             nerd font + symbol/ancient-script fallbacks
  omp.nix               omp settings and model-pinned dev subagents
  cli/                  one file per program
  skills/               omp skills shared by every user
users/<user>/
  default.nix           entry point: imports modules/home.nix, sets identity
  <host>.nix            optional per-host additions
```

A user directory holds only what differs from `modules/`.

## What's in it

**Shell.** zsh (autosuggestions, syntax highlighting, [fzf-tab] from master),
starship, tmux with [tmux-agent-indicator] and sesh, fzf, carapace completions
rendered through fzf-tab, eza, zoxide as `cd`, atuin, direnv with nix-direnv,
git, and Neovim from [quanchobi/nixvim]. One-off tools that need no
configuration come from the host's package manager instead.

**omp.** `modules/omp.nix` sets omp preferences and adds `*-dev` subagents, each
pinned to one model. `modules/skills` links in `frontend-design`
([anthropics/skills]), `lxd` ([canonical/openstack-agentic-skills]), and the
local `tmux` and `agent-indicator` skills, plus the `tmux-agent` script the
latter documents. On the desktop, `users/anderson/desktop.nix` adds a llama.cpp
provider at `127.0.0.1:8080`, FreeCAD/Blender/ComfyUI MCP servers, and the
`freecad-design` skill.

**SSH.** `users/anderson/ssh.nix` sets connection multiplexing and keepalives
only. Host blocks go in an untracked `~/.ssh/hosts`, which the generated
config includes, so hostnames stay out of this public repo.

## Behavior worth knowing

- **omp config is merged, not linked.** omp rewrites `~/.omp/agent/config.yml`
  and `mcp.json` itself, so activation deep-merges the Nix-managed keys into the
  existing files. Managed keys win on every switch; anything omp writes
  survives. The merge only adds: removing a key here does not remove it from
  the file, so delete it there by hand.
- **MCP servers are pinned.** `freecad-mcp` and `mcp-for-blender` run through
  `uvx` at fixed versions in `desktop.nix`. Bump `freecad-mcp` together with the
  FreeCAD addon (same tag).
- **`stateVersion` is `24.05`.** Don't change it without reading the Home
  Manager release notes.

## Adding things

- **User:** create `users/<user>/default.nix` importing `../../modules/home.nix`
  and setting `home.username`, then add
  `"<user>" = mkHome "<system>" [ ./users/<user> ];` to `homeConfigurations`
  and the name to the build matrix in `.github/workflows/check.yml`.
- **Host:** add `users/<user>/<host>.nix` and a `"<user>@<hostname>"` entry
  that lists it after `./users/<user>`.
- **CLI program:** add `modules/cli/<program>.nix` and import it from
  `modules/cli/default.nix`.

## Maintenance

```sh
nix fmt                # nixfmt, deadnix, statix, prettier, shellcheck, shfmt
nix flake check        # formatting + nixosModules.default on a minimal NixOS system
nix flake update       # bump all inputs, including the non-flake skill repos
```

CI (`.github/workflows/check.yml`) runs `nix flake check` and builds every
`homeConfigurations` entry on each push and PR. `update-flake.yml` opens a
`flake.lock` update PR on the 1st of each month and dispatches the checks on it.

[fzf-tab]: https://github.com/Aloxaf/fzf-tab
[tmux-agent-indicator]: https://github.com/quanchobi/tmux-agent-indicator
[quanchobi/nixvim]: https://github.com/quanchobi/nixvim
[anthropics/skills]: https://github.com/anthropics/skills
[canonical/openstack-agentic-skills]: https://github.com/canonical/openstack-agentic-skills
