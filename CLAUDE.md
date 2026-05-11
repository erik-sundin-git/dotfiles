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
| `nomad` | NixOS laptop (nixosConfigurations) | `#nomad` | `hosts/nomad/` |
| `forge` | Debian desktop (homeConfigurations) | `#forge` | `hosts/forge.nix` |
| `ether` | NixOS VM (nixosConfigurations) | `#ether` | `hosts/ether/` |
| `specter` | NixOS laptop (nixosConfigurations) | `#specter` | `hosts/specter/` |

Each host configuration sets `systemConstants.system.host` and `systemConstants.system.type`, which downstream modules (e.g. `shell/bash/aliases.nix`) use to vary behavior per host.

## Nix Commands

```bash
# Apply (preferred — uses nh wrapper)
rebuild                                        # per-host alias: nh home/os switch ~/dotfiles -c <host>

# Apply (direct fallback)
home-manager switch -b backup --flake ~/dotfiles#forge
sudo nixos-rebuild switch --flake ~/dotfiles#ether
sudo nixos-rebuild switch --flake ~/dotfiles#specter
sudo nixos-rebuild switch --flake ~/dotfiles#nomad

# Build without applying
home-manager build --flake ~/dotfiles#forge

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
│   ├── flake-parts []/          # Core setup: imports den, flake-parts, import-tree wiring; pkgs-by-name overlay
│   ├── nh.nix                   # programs.nh: flake path + auto-cleanup (keep 7d/5 gens)
│   └── tools/home-manager [ND]/ # Home Manager NixOS module (not auto-applied)
├── hosts/
│   ├── nomad/                   # NixOS laptop — commonDesktop + i3Stack(nixos) + homeManager (commonHome + i3Stack + alacritty + vpn); uses startx
│   ├── forge.nix                # Debian desktop — debianMinimal + commonHome + i3Stack + alacritty; uses nixGLNvidia
│   ├── ether/                   # NixOS VM — full NixOS config + embedded homeManager
│   ├── specter/                 # NixOS laptop — commonDesktop + i3Stack(nixos) + embedded homeManager (commonHome + i3Stack); uses startx
│   ├── live-iso.nix             # Bootable NixOS ISO — GNOME, git, emacs, dotfiles at /etc/dotfiles, prepare-disk install script
│   ├── common/
│   │   ├── home-manager/commonHome # Import hub: systemConstants, theme, emacs, librewolf, bash, nh; sets .xinitrc/.xprofile/.Xresources
│   │   └── nixos/               # commonConfig (base NixOS + trusted-users) + commonDesktop (X server, pipewire, users)
│   ├── debian-minimal.nix       # Debian base: nixGL wrapping, NUR overlay, allowUnfree
│   └── topology.nix             # Registers hosts: den.homes / den.hosts + stateVersion
├── system-constants/
│   ├── system-constants.nix     # Options: adminName, adminEmail, system.host/type, lat/lon, thermalZonePath
│   ├── theme.nix                # Options: selectedTheme (str) + theme (attrsOf str palette)
│   └── themes/onedark.nix       # One Dark palette; sets config.theme via mkIf selectedTheme == "onedark"
├── stacks/
│   └── i3-stack.nix             # homeManager: i3 + polybar + gtk + redshift + dunst; nixos: bluetooth
├── services/
│   ├── bluetooth/               # NixOS: hardware.bluetooth + blueman
│   ├── dunst.nix                # Notification daemon; themed via config.theme
│   ├── redshift.nix
│   └── vpn/                     # WireGuard tools, proton-vpn-cli, vpn-status script, gnome-keyring
├── browsers/
│   ├── chromium/
│   └── librewolf/
├── shell/bash/                  # Bash aliases (per-host `rebuild`) and config
└── programs/
    ├── helpers.nix              # _module.args: mkColors (i3 window color sets), mkScreenshot
    ├── emacs/                   # Symlinks emacs dotfiles from repo via home.file
    ├── gtk/                     # Arc-Dark theme; injects selection/accent colors via extraCss
    ├── i3/                      # i3wm, keybindings, modes, picom
    ├── alacritty/               # Alacritty with nixGL wrapping + theme colors
    ├── xfce/                    # XFCE (ether only)
    ├── cli-tools/               # CLI packages (generic + NixOS-specific)
    └── mail/                    # ProtonMail Bridge + mbsync + notmuch + msmtp

nix/packages/
└── airpods-status/              # Custom package — auto-exposed as pkgs.local.airpods-status via overlay
```

**Host wiring via `den`**: Hosts are defined using `den.aspects.<host> = { homeManager = ...; }` (or `nixos = ...`). The `topology.nix` registers them into `homeConfigurations`/`nixosConfigurations` via `den.homes.x86_64-linux.<host>` and `den.hosts.x86_64-linux.<host>`. There is no `lib.nix` with `mkNixos`/`mkHomeManager`.

**nixGL on Debian**: The `debianMinimal` module provides a `debianGL.nixGLPackage` option. When set, it wraps GL-dependent binaries (alacritty, kitty) with the specified nixGL package so they work on non-NixOS systems. forge uses `nixGLNvidia`.

**Live ISO**: Built with `nix build .#iso`. The `prepare-disk /dev/nvme0n1` script partitions, formats, mounts, clones the dotfiles repo, patches `hosts/nomad/hardware.nix` with generated UUIDs, and runs `nixos-install --flake /tmp/dotfiles#nomad` in one shot.

**Theme system**: `config.theme` is a flat `attrsOf str` map (semantic name → `#rrggbb`). The active theme is selected via `config.selectedTheme` (default `"onedark"`). Each theme file in `system-constants/themes/` sets `config.theme` via `mkIf`. UI modules (i3, alacritty, polybar, gtk) consume it via `let c = config.theme; in ...`. `generic.theme` must be imported before any UI module that reads `config.theme` — `commonHome` does this for all Debian hosts. To add a new theme, add a file to `themes/` following the same pattern.

**Custom packages**: Files under `nix/packages/<name>/package.nix` are auto-picked up by `pkgs-by-name` and exposed as `pkgs.local.<name>` via `flake.overlays.default`. After adding a new package directory, `git add` it immediately.

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
