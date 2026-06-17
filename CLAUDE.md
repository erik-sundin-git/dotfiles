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
| `forge` | NixOS desktop (nixosConfigurations) | `#forge` | `hosts/forge/` |
| `ether` | NixOS VM (nixosConfigurations) | `#ether` | `hosts/ether/` |
| `specter` | NixOS laptop (nixosConfigurations) | `#specter` | `hosts/specter/` |

Each host configuration sets `systemConstants.system.host` and `systemConstants.system.type`, which downstream modules (e.g. `shell/bash/aliases.nix`) use to vary behavior per host.

## Nix Commands

```bash
# Apply (preferred — uses nh wrapper)
rebuild                                        # per-host alias: nh home/os switch ~/dotfiles -c <host>

# Apply (direct fallback)
sudo nixos-rebuild switch --flake ~/dotfiles#forge
sudo nixos-rebuild switch --flake ~/dotfiles#ether
sudo nixos-rebuild switch --flake ~/dotfiles#specter
sudo nixos-rebuild switch --flake ~/dotfiles#nomad

# Build without applying
nix build .#nixosConfigurations.forge.config.system.build.toplevel

# Update flake inputs
nix flake update

# Check flake outputs
nix flake show

# Evaluate every host (catches regressions across refactors without building)
nix flake check --no-build

# Format Nix files
nixfmt <file>
```

## Nix Architecture

`flake.nix` is a one-liner that delegates everything to `nix/modules/` via `import-tree`, which recursively imports all `.nix` files. The architecture follows the dendritic pattern — `flake-parts` as the module system, with `import-tree` auto-importing all modules.

Key conventions:
- **`flake-parts []` directories** — brackets signal to `import-tree` that these are flake-parts modules (not Home Manager modules)
- **`[ND]` directories** — "Not Default"; modules are available but not auto-applied, must be explicitly imported
- Modules expose themselves via `flake.modules.homeManager.<name>`, `flake.modules.nixos.<name>`, or `flake.modules.generic.<name>` (for platform-neutral modules like `systemConstants`)
- A single `.nix` file can define multiple module types (e.g. both `flake.modules.nixos.hyprland` and `flake.modules.homeManager.hyprland` in the same file) — the stack then imports both by name

Module layout:
```
nix/modules/
├── nix/
│   ├── flake-parts []/          # Core setup: imports den, flake-parts, import-tree wiring; pkgs-by-name overlay
│   ├── nh.nix                   # programs.nh: flake path + auto-cleanup (keep 7d/5 gens)
│   └── tools/home-manager [ND]/ # Home Manager NixOS module (not auto-applied)
├── hosts/
│   ├── nomad/                   # NixOS laptop — commonDesktop + swayfxStack(nixos) + virtManager; homeManager: commonHome + swayfxStack + alacritty + vpn
│   ├── forge/                   # NixOS desktop — commonDesktop + i3Stack(nixos); homeManager: commonHome + i3Stack + alacritty + vpn
│   ├── ether/                   # NixOS VM — full NixOS config + embedded homeManager
│   ├── specter/                 # NixOS laptop — commonDesktop + swayfxStack(nixos); homeManager: commonHome + swayfxStack
│   ├── live-iso/                # Bootable NixOS ISO — TTY-only, git, emacs, claude-code, dotfiles at /etc/dotfiles, prepare-disk install script
│   ├── common/
│   │   ├── home-manager/commonHome # Import hub: systemConstants, theme, emacs, librewolf, bash, nh; sets .xinitrc/.xprofile/.Xresources
│   │   └── nixos/               # commonConfig (base NixOS + trusted-users) + commonDesktop (X server, pipewire, users)
│   └── topology.nix             # Registers hosts: den.hosts (NixOS) + den.homes (standalone HM) + stateVersion
├── system-constants/
│   ├── system-constants.nix     # Options: adminName, adminEmail, system.host/type, lat/lon, thermalZonePath, wallpaper, keyboard.{layout,options}, network.forgeHost
│   ├── theme.nix                # Options: selectedTheme (str) + theme (attrsOf str palette); asserts theme palette is non-empty
│   └── themes/onedark.nix       # One Dark palette; sets config.theme via mkIf selectedTheme == "onedark"
├── stacks/
│   ├── i3-stack.nix             # homeManager: i3 + polybar + gtk + redshift + dunst + starship; nixos: bluetooth + i3
│   ├── hyprland-stack.nix       # homeManager: hyprland + waybar + gtk + dunst + starship + gammastep; nixos: bluetooth + hyprland
│   ├── swayfx-stack.nix         # homeManager: swayfx + waybar + gtk + dunst + starship + gammastep; nixos: bluetooth + swayfx
│   └── xfce-stack.nix           # nixos: xfce + theme; homeManager: gtk (ether only — host imports xfceStack explicitly on both layers)
├── services/
│   ├── airstatus.nix            # homeManager: services.airstatus.enable + systemd user unit; uses pkgs.local.airstatus
│   ├── bluetooth/               # NixOS-only module (hardware.bluetooth + blueman) — no homeManager variant exists
│   ├── dunst.nix                # Notification daemon; themed via config.theme
│   ├── redshift.nix
│   ├── gammastep.nix            # Wayland equivalent of redshift (used by hyprland-stack and swayfx-stack)
│   ├── picom.nix                # X11 compositor; used by i3-stack
│   ├── pulseaudio.nix           # NixOS: services.pulseaudio with pulseaudioFull (used where pipewire isn't)
│   ├── steam.nix                # NixOS: programs.steam + remotePlay/dedicatedServer firewall holes
│   ├── virt-manager/            # NixOS: libvirtd + QEMU KVM + spice USB + virt-manager; used by nomad
│   └── vpn/                     # WireGuard tools, proton-vpn-cli, vpn-status + vpn-toggle scripts, gnome-keyring
├── browsers/
│   ├── chromium/
│   ├── firefox/                 # Imported by commonHome
│   └── librewolf/
├── shell/bash/                  # Bash aliases (per-host `rebuild`) and config
└── programs/
    ├── helpers.nix              # _module.args (uiHelpers): mkColors, mkScreenshot (X11/maim), waylandScreenshots, mkModeNotif, hexToRgba, hexToHyprRgb
    ├── wayland-base.nix         # nixos.waylandBase: NIXOS_OZONE_WL + QT_QPA_PLATFORM + base xdg.portal; homeManager.waylandBase: emacs-pgtk; imported by hyprland + swayfx (both layers)
    ├── desktop-apps.nix         # homeManager bundle: freetube, qbittorrent, protonmail-desktop, beeper, multiviewer-for-f1, vlc, htop, ffmpeg, yt-dlp
    ├── emacs/                   # Symlinks emacs dotfiles from repo via home.file
    ├── gaming/                  # nixos.gaming: Intel iGPU (i915 kernel params + iHD VA-API), latest kernel, thermald, zramSwap
    ├── gh.nix                   # homeManager: gh CLI + git credential helper for github.com
    ├── gtk/                     # Arc-Dark theme; injects selection/accent colors via extraCss
    ├── i3/                      # i3wm, keybindings, modes
    ├── hyprland/                # homeManager: Hyprland (hy3 plugin), keybindings, submaps, packages; nixos: programs.hyprland + UWSM + portal config (imports waylandBase)
    ├── swayfx/                  # homeManager: SwayFX compositor, keybindings, modes, packages, for_window browser rules; nixos: programs.sway + wlr portal (imports waylandBase)
    ├── polybar/                 # Polybar bar + themed modules (ethernet, wireless, vpn, system, ipv6); uses nixpkgs-stable for polybarFull
    ├── waybar/                  # Waybar config + themed CSS; uses hexToRgba from helpers.nix
    ├── alacritty/               # Alacritty + theme colors
    ├── xfce/                    # XFCE (ether only)
    ├── cli-tools/               # CLI packages (generic + NixOS-specific)
    └── mail/                    # ProtonMail Bridge + mbsync + notmuch + msmtp

nix/packages/
└── airstatus/                   # AirPods battery monitor (Python + bleak); exposes pkgs.local.airstatus
```

**Host wiring via `den`**: Hosts are defined using `den.aspects.<host> = { nixos = ...; }` (or `homeManager = ...` for standalone Home Manager). `topology.nix` registers NixOS hosts via `den.hosts.x86_64-linux.<host>` and standalone HM hosts via `den.homes.x86_64-linux.<host>`. There is no `lib.nix` with `mkNixos`/`mkHomeManager`.

**Critical**: `den.aspects.<name>` must exactly match the name registered in `topology.nix`. A mismatch means the aspect is never applied to the host — NixOS gets an empty config and fails with "boot loader not configured".

**Live ISO**: Built with `nix build .#iso`. The `prepare-disk /dev/nvme0n1` script partitions, formats, mounts, clones the dotfiles repo, patches `hosts/nomad/hardware.nix` with generated UUIDs, and runs `nixos-install --flake /tmp/dotfiles#nomad` in one shot.

**Theme system**: `config.theme` is a flat `attrsOf str` map (semantic name → `#rrggbb`). The active theme is selected via `config.selectedTheme` (default `"onedark"`). Each theme file in `system-constants/themes/` sets `config.theme` via `mkIf`. UI modules (i3, alacritty, polybar, gtk, hyprland, waybar) consume it via `let c = config.theme; in ...`. `generic.theme` must be imported before any UI module that reads `config.theme` — `commonHome` does this for all hosts. To add a new theme, add a file to `themes/` following the same pattern. A typo in `selectedTheme` is caught by an assertion in `theme.nix` (empty palette → build failure). Color-format helpers in `helpers.nix`: `hexToRgba` (waybar/GTK CSS — GTK does not accept `alpha(#rrggbb, a)` with hex literals) and `hexToHyprRgb` (hyprland `rgb()` form).

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
