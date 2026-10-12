# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Git

Never add `Co-Authored-By` trailers to commits.

When creating new files in this repo, always `git add` them immediately — Nix flakes only see git-tracked files and will fail with "undefined variable" otherwise.

When the user says "push", commit all pending changes as one or more logically grouped commits and push to the remote.

## What This Repo Is

Personal dotfiles for Erik Sundin: a single Nix flake producing NixOS configurations (with Home Manager embedded as a NixOS module) for several hosts. Everything lives under `nix/`; the repo root holds only `flake.nix`/`flake.lock`. Keep it that way: non-Nix files that modules reference go in `nix/assets/`, which is outside `nix/modules/`, so import-tree never tries to import them.

## Hosts

| Host | Kind | Desktop | Notes |
|------|------|---------|-------|
| `nomad` | ThinkPad T480s laptop | swayfxStack | + gaming, virtManager, geforcenow, curseforge; NAT forward to a libvirt VM; theme `catppuccin` |
| `forge` | Desktop | i3Stack | + gaming, virtManager; autorandr dual-monitor profile |
| `specter` | Laptop | swayfxStack | |
| `ether` | VM | xfceStack | GRUB on `/dev/vda` (`commonConfig.bootEFI = false`) |
| `wisp` | Headless server | none | `commonConfig` only (not `commonDesktop`) + `gtnh` Minecraft server; lid/suspend disabled |
| `live-iso` | ISO | none | Plain `nixosSystem`, not a den host; built with `nix build .#iso` |

Each host sets `systemConstants.system = { host; type; }` (`type` ∈ laptop/desktop/server) on **both** the NixOS and Home Manager layers. Downstream modules branch on it (e.g. `isLaptop`, the per-host `rebuild` alias, TLP enabled only on laptops).

## Commands

```bash
rebuild                                   # alias → nh os switch ~/dotfiles#<host>
nh os switch ~/dotfiles#nomad             # same, explicit (aliases don't load in non-interactive shells / `!` commands)
nix flake check --no-build                # evaluate every host — fastest regression check after refactors
nix build .#nixosConfigurations.forge.config.system.build.toplevel   # build without switching
nix eval .#nixosConfigurations.nomad.config.<option.path>            # inspect a single resolved option
nix build .#iso                           # live installer ISO
nix flake update                          # bump inputs
nixfmt <file>
```

There are no tests; evaluation (`nix flake check --no-build`) is the check.

## Nix Architecture

`flake.nix` is a one-liner: `flake-parts.lib.mkFlake … (import-tree ./nix/modules)`. Every `.nix` file under `nix/modules/` is auto-imported as a flake-parts module (dendritic pattern). There is no central import list — **a new file is live as soon as it's `git add`ed**.

- Files never contain plain NixOS/HM modules directly. They define named modules: `flake.modules.nixos.<name>`, `flake.modules.homeManager.<name>`, or `flake.modules.generic.<name>` (usable in both layers, e.g. `systemConstants`, `theme`). One file may define several types under the same name (e.g. `swayfx` has both `nixos` and `homeManager`), and several files may contribute to the same name — they merge (e.g. `programs/swayfx/*.nix` all define `homeManager.swayfx`; both theme files define `generic.theme`).
- Consumers import by name: `imports = with inputs.self.modules.nixos; [ commonDesktop swayfxStack ];`.
- `flake-parts []` and `[ND]` in directory names are import-tree markers: `[]` = core flake-parts setup, `[ND]` = "not default".

**Host wiring via `den`:** `hosts/topology.nix` registers `den.hosts.x86_64-linux.<host>`; each host file defines `den.aspects.<host>.nixos`. The names must match exactly — a mismatch silently applies nothing and NixOS fails with "boot loader not configured". Home Manager is pulled in per host via `inputs.home-manager.nixosModules.home-manager`; user config goes in `home-manager.users.erik`, shared HM modules via `home-manager.sharedModules`.

**Layering for desktop hosts:**
- `commonConfig` (`hosts/common/nixos/common-nixos.nix`): base system, nix settings, TLP, systemd-boot, `useGlobalPkgs`, and key-only OpenSSH (the authorized key for `erik` lives here; password login is disabled).
- `commonDesktop` (`common-desktop.nix`): imports `commonConfig`; X server/xkb (which also enables **LightDM**), users, overlays, and HM `sharedModules` = `commonHome` + alacritty + desktopApps + vpn.
- `commonHome` (`hosts/common/home-manager/common-home.nix`): imports `generic.systemConstants` + `generic.theme`, emacs, browsers, bash, nh; sets `_module.args.isLaptop`.
- Stacks (`stacks/*-stack.nix`) bundle a WM's NixOS side + HM side. A stack's `nixos` module adds its HM half through `home-manager.sharedModules`, so hosts only import the NixOS stack.

**Module arguments injected via `_module.args`** (don't look for them in nixpkgs):
- `pkgsUnstable`: nixpkgs-unstable, from `system-constants/system-constants.nix`. Available wherever `systemConstants` is imported.
- `isLaptop`: from `commonHome`.
- `mkColors`, `mkScreenshot`, `waylandScreenshots`, `hexToRgba`, `hexToHyprRgb`, `mkModeNotif`: from `programs/helpers.nix` (HM module `uiHelpers`).
- `swayBindingsData`: from `programs/swayfx/bindings-data.nix`. This is the **single source of truth** for sway keybindings. `keybindings.nix`, `modes.nix` and the `sway-help` cheatsheet in `packages.nix` all derive from it, so edit binds there.

**Theme system** (`system-constants/theme.nix` + `themes/*.nix`): `selectedTheme` is an **enum**, so adding a theme means adding a `themes/<name>.nix` (setting `config.theme` under `mkIf (selectedTheme == "<name>")`) *and* extending the enum. `config.theme` is a submodule: free-form `name = "#rrggbb"` colors plus typed knobs `rounding`, `gaps`, `opacity`, `blur`, `fontFamily`. UI modules read it as `let c = config.theme; in …`. An assertion fails the build if the palette is empty. GTK CSS doesn't accept `alpha(#hex, a)`; use `hexToRgba`.

**Custom packages:** `nix/packages/<name>/package.nix` (curseforge, geforcenow, irealpro) is auto-discovered by pkgs-by-name and exposed as `pkgs.local.<name>` via `flake.overlays.default`. A host needs that overlay in `nixpkgs.overlays` (`commonDesktop` adds it; `wisp` adds it itself).

## Gotchas

- **Audio is PulseAudio on all desktop hosts** (`commonDesktop` sets `services.pipewire.enable = false`; the `pulseaudio` and `bluetooth` modules enable PulseAudio). As a result, `xdg-desktop-portal-wlr` is gated on PipeWire in `programs/swayfx/swayfx.nix`, because without PipeWire it crash-loops and stalls the portal (waybar then hangs on startup). It also means Wayland screen sharing doesn't work.
- **Sway hosts start sway from LightDM**, not from the `exec sway` on tty1 in the swayfx module's `bash.profileExtra`. Disabling the display manager kills the running session during `switch`.
- `gaming` imports the `geforcenow` NixOS module (flatpak + a oneshot install service), so any host that imports `gaming` gets it. It also sets `linuxPackages_latest`, zram, nix-ld and Steam. Intel GPU settings (i915 params, VA-API, thermald) live in `nomad.nix`.
- Firefox and LibreWolf share search engines, base prefs and extensions through the `mozillaShared` module arg (`browsers/mozilla-shared.nix`); edit shared bits there.
- `homeManager.nh` points `programs.nh.flake` at `~/dotfiles`, so a bare `nh os switch` uses the working tree.
- To override a value nixpkgs sets at normal priority (e.g. `xdg.portal.wlr.enable` from the sway module), use `lib.mkForce`; a plain assignment will error with conflicting definitions.

## Assets (`nix/assets/`)

- `emacs.d/`: based on minimal-emacs.d, using straight.el + use-package. Customisation lives in `post-init.el`; `pre-init.el` bootstraps straight. Linked into `~/.emacs.d/` by `programs/emacs/emacs.nix` via `home.file`. Wayland hosts get `emacs-pgtk` via `homeManager.waylandBase`.
- `wallpapers/`: default `systemConstants.wallpaper`.

forge (i3) is not in active use. Its i3 session starts from LightDM via a `home-manager` session that runs the HM-generated `~/.hm-xsession` (`nixos.i3` + `xsession.enable` in `homeManager.i3`).

## Secrets (`nix/secrets/`)

The repo is public, so private data goes in `nix/secrets/`, which sits outside `nix/modules/`.
- `hosts.nix`: the LAN inventory (`{ <name> = { ip; user ? "erik"; }; }`). It's **git-crypt encrypted**, so the repo must be unlocked (`git-crypt unlock ~/.config/git-crypt/dotfiles.key`) or eval fails. It's exposed as `systemConstants.network.hosts`, and `homeManager.ssh` (`shell/ssh.nix`) turns every entry into an ssh `matchBlock`, so use `ssh <host>` (e.g. `ssh wisp`) to reach hosts. Read the file for IPs. Never hardcode a LAN IP in a module.
- Encryption is driven by `nix/secrets/.gitattributes`. Add a file's entry there **before** `git add`ing the file, then confirm with `git-crypt status nix/secrets`.
- Runtime secrets (passwords, tokens) go in `secrets.yaml` via **sops-nix** (`nix/modules/nix/sops.nix`, imported by `commonConfig`). It stays inactive until `secrets.yaml` exists. Recipients are in `nix/secrets/.sops.yaml` (admin key + one age key per host from `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`), and `sops` must run from `nix/secrets/`. Declare `sops.secrets.<name>` and read `config.sops.secrets.<name>.path`. The values never enter the nix store.

## Mail

`programs/mail/mail.nix` (`homeManager.mail`): ProtonMail Bridge user service, mbsync on a systemd timer, notmuch indexing, msmtp for sending. **No host currently imports it.** Desktop hosts use the `protonmail-desktop` app (autostarted in sway) instead.
