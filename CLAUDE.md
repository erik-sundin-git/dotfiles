# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git

Never add `Co-Authored-By` trailers to commits.

When creating new files in this repo, always `git add` them immediately — Nix flakes only see git-tracked files and will fail with "undefined variable" otherwise.

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
│   ├── flake-parts []/          # Core setup: imports den, flake-parts, import-tree wiring
│   └── tools/home-manager [ND]/ # Home Manager NixOS module (not auto-applied)
├── hosts/
│   ├── nomad.nix                # Debian laptop — imports debianMinimal, minimalConfig, i3, polybar, picom, alacritty, vpn
│   ├── forge.nix                # Debian desktop — same minus vpn; uses nixGLNvidia
│   ├── ether/                   # NixOS VM — full NixOS config + embedded homeManager
│   ├── common/nixos/            # Shared NixOS config (commonConfig module)
│   ├── debian-minimal.nix       # Debian base: nixGL wrapping, NUR overlay, allowUnfree
│   └── topology.nix             # Registers hosts: den.homes / den.hosts + stateVersion
├── minimal-config/              # Base Home Manager defaults (keyboard, locale, xsession)
├── system-constants/
│   ├── system-constants.nix     # Options: adminName, adminEmail, system.host/type, lat/lon, thermalZonePath
│   └── colors.nix               # One Dark palette exposed as config.colors (attrsOf str)
├── browsers/
│   ├── chromium/
│   └── librewolf/
├── shell/bash/                  # Bash aliases (per-host `rebuild`) and config
├── vpn/                         # WireGuard tools, proton-vpn-cli, vpn-status script, gnome-keyring
└── programs/
    ├── emacs/                   # Symlinks emacs dotfiles from repo via dotPath
    ├── i3/                      # i3wm, keybindings, modes, polybar, picom
    ├── alacritty/               # Alacritty with nixGL wrapping + One Dark colors
    ├── xfce/                    # XFCE (ether only)
    ├── cli-tools/               # CLI packages (generic + NixOS-specific)
    └── mail/                    # ProtonMail Bridge + mbsync + notmuch + msmtp
```

**Host wiring via `den`**: Hosts are defined using `den.aspects.<host> = { homeManager = ...; }` (or `nixos = ...`). The `topology.nix` registers them into `homeConfigurations`/`nixosConfigurations` via `den.homes.x86_64-linux.<host>` and `den.hosts.x86_64-linux.<host>`. There is no `lib.nix` with `mkNixos`/`mkHomeManager`.

**nixGL on Debian**: The `debianMinimal` module provides a `debianGL.nixGLPackage` option. When set, it wraps GL-dependent binaries (alacritty, kitty) with the specified nixGL package so they work on non-NixOS systems. nomad uses `nixGLIntel`, forge uses `nixGLNvidia`.

**Color system**: `config.colors` is a flat `attrsOf str` map (semantic name → `#rrggbb`) defined in `system-constants/colors.nix`. All UI modules (i3, alacritty, polybar) reference it via `let c = config.colors; in ...`.

## Static Dotfiles

Several directories contain static config files that are symlinked or used directly (not generated by Nix):

- `i3/.config/i3/` — static i3 config (legacy; active i3 config is Nix-generated via `xsession.windowManager.i3`)
- `picom/.config/picom/picom.conf` — static picom config (legacy; active config is Nix-generated)
- `starship/.config/starship.toml` — Starship prompt config
- `nitrogen/` — wallpaper settings (restored at i3 startup via `nitrogen --restore`)
- `xorg/.xinitrc` — X session init script

## Emacs Configuration

Located in `emacs/.emacs.d/`. Based on [minimal-emacs.d](https://github.com/jamescherti/minimal-emacs.d). Uses `straight.el` + `use-package`. Main customization lives in `post-init.el`; `pre-init.el` bootstraps straight.el. The Nix module (`programs/emacs/emacs.nix`) symlinks these files into `~/.emacs.d/` via `home.file`.

## Mail Setup

Managed by `nix/modules/programs/mail/mail.nix`. Systemd services/timers run mbsync periodically; notmuch indexes mail. ProtonMail Bridge runs as a service. Sending via msmtp.
