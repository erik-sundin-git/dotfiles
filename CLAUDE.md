# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal dotfiles for Erik Sundin. The Nix flake manages a Home Manager configuration for a Debian laptop. Non-Nix dotfiles (emacs, i3, qtile, bash, zsh, etc.) are managed separately via symlinks or a bare git approach.

## Nix Commands

```bash
# Apply Home Manager configuration
home-manager switch --flake .#debian

# Build without applying
home-manager build --flake .#debian

# Update flake inputs
nix flake update

# Check flake outputs
nix flake show

# Format Nix files
nixfmt <file>
```

## Nix Architecture

The flake (`flake.nix`) delegates everything to `nix/modules/` via `import-tree`, which recursively imports all `.nix` files. The architecture uses the [dendritic pattern](https://github.com/hercules-ci/flake-parts) — `flake-parts` as the module system, with `import-tree` auto-importing all modules.

Key conventions:
- **`flake-parts []` directories** — brackets signal to `import-tree` that these are flake-parts modules (not Home Manager modules)
- **`[ND]` directories** — "Not Default"; modules here are available but not auto-applied
- Modules expose themselves via `flake.modules.homeManager.<name>` or `flake.modules.nixos.<name>`

Module layout:
```
nix/modules/
├── nix/
│   ├── flake-parts []/          # Core flake-parts setup (dendritic-tools, lib, factory)
│   └── tools/home-manager [ND]/ # Home Manager flake integration
├── hosts/debian-laptop/         # Host config — imports modules, sets username/homeDirectory
├── minimal-config/              # Base Home Manager defaults (keyboard, locale, xsession)
├── systemConstants/             # Global constants (admin name, email, config dir)
└── programs/
    ├── emacs/                   # Symlinks emacs dotfiles via dotPath
    ├── i3/                      # i3wm config, keybindings, modes, i3status
    ├── cli-tools/               # CLI packages (git, alacritty, htop, etc.)
    └── mail/                    # ProtonMail Bridge + mbsync + notmuch + msmtp
```

The debian host (`hosts/debian-laptop/configuration.nix`) currently imports: `minimal-config`, `emacs`, `i3`.

The `lib.nix` helpers `mkNixos` and `mkHomeManager` wire a named module into `nixosConfigurations` or `homeConfigurations` respectively. The debian host is a `homeConfigurations` entry (not a full NixOS system).

## Emacs Configuration

Located in `emacs/.emacs.d/`. Based on [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d). Uses `straight.el` + `use-package`. Main customization lives in `post-init.el`; `pre-init.el` bootstraps straight.el.

## Mail Setup

Managed by `nix/modules/programs/mail/mail.nix`. Systemd services/timers run mbsync periodically; notmuch indexes mail. ProtonMail Bridge runs as a service. Sending via msmtp.
