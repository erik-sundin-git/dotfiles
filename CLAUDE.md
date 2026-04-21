# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal dotfiles for Erik Sundin. The Nix flake manages Home Manager and NixOS configurations across multiple hosts. Non-Nix dotfiles (emacs, i3, bash, zsh, etc.) live in their own directories and are symlinked or managed via a bare git approach.

## Hosts

| Name | Type | Flake target | Config file |
|------|------|-------------|-------------|
| `nomad` | Debian laptop (homeConfigurations) | `#nomad` | `hosts/nomad/` |
| `forge` | Debian desktop (homeConfigurations) | `#forge` | `hosts/forge/` |
| `ether` | NixOS VM (nixosConfigurations) | `#ether` | `hosts/ether/` |

Each host configuration sets `systemConstants.system.host` and `systemConstants.system.type`, which downstream modules (e.g. `shell/bash/aliases.nix`) use to vary behavior per host.

## Nix Commands

```bash
# Apply Home Manager (laptop/desktop)
home-manager switch -b backup --flake ~/dotfiles#nomad
home-manager switch -b backup --flake ~/dotfiles#forge

# Apply NixOS (VM)
sudo nixos-rebuild switch --flake ~/dotfiles#ether

# Or use the per-host `rebuild` shell alias (set automatically)

# Build without applying
home-manager build --flake ~/dotfiles#nomad

# Update flake inputs
nix flake update

# Check flake outputs
nix flake show

# Format Nix files
nixfmt <file>
```

## Nix Architecture

`flake.nix` is a one-liner that delegates everything to `nix/modules/` via `import-tree`, which recursively imports all `.nix` files. The architecture follows the dendritic pattern — `flake-parts` as the module system, with `import-tree` auto-importing all modules.

Key conventions:
- **`flake-parts []` directories** — brackets signal to `import-tree` that these are flake-parts modules (not Home Manager modules)
- **`[ND]` directories** — "Not Default"; modules are available but not auto-applied, must be explicitly imported
- Modules expose themselves via `flake.modules.homeManager.<name>`, `flake.modules.nixos.<name>`, or `flake.modules.generic.<name>` (for platform-neutral modules like `systemConstants`)

Module layout:
```
nix/modules/
├── nix/
│   ├── flake-parts []/          # Core setup: dendritic-tools, lib (mkNixos/mkHomeManager), factory
│   └── tools/home-manager [ND]/ # Home Manager flake integration (not auto-applied)
├── hosts/
│   ├── nomad/                   # Debian laptop — imports minimal-config, emacs, i3, bash
│   ├── forge/                   # Debian desktop — imports minimal-config, bash
│   └── ether/                   # NixOS VM — full NixOS + embedded homeManager module
├── minimal-config/              # Base Home Manager defaults (keyboard, locale, xsession)
├── systemConstants/             # Global options: adminName, adminEmail, system.host/type, lat/lon, colors
├── browsers/
│   ├── chromium/
│   └── librewolf/
├── shell/bash/                  # Bash aliases (including per-host `rebuild`) and config
└── programs/
    ├── emacs/                   # Symlinks emacs dotfiles from repo via dotPath
    ├── i3/                      # i3wm config, keybindings, modes, i3status
    ├── cli-tools/               # CLI packages (generic + NixOS-specific)
    └── mail/                    # ProtonMail Bridge + mbsync + notmuch + msmtp
```

`lib.nix` provides `mkNixos` and `mkHomeManager` — they wire a named module into `nixosConfigurations` or `homeConfigurations`. Each host's `flake-parts.nix` calls one of these helpers.

## Emacs Configuration

Located in `emacs/.emacs.d/`. Based on [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d). Uses `straight.el` + `use-package`. Main customization lives in `post-init.el`; `pre-init.el` bootstraps straight.el. The Nix module (`programs/emacs/emacs.nix`) symlinks these files into `~/.emacs.d/` via `home.file`.

## Mail Setup

Managed by `nix/modules/programs/mail/mail.nix`. Systemd services/timers run mbsync periodically; notmuch indexes mail. ProtonMail Bridge runs as a service. Sending via msmtp.
