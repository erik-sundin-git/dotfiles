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
| `nomad` | ThinkPad T480s laptop | swayfxStack (`laptopProfile`) | + gaming, virtManager, geforcenow; NAT forward to a libvirt VM; theme `ef-bio` |
| `forge` | Desktop | i3Stack | `desktopBaseProfile` + i3Stack; + gaming, virtManager; autorandr dual-monitor profile |
| `specter` | Laptop | swayfxStack | |
| `ether` | VM | xfceStack | GRUB on `/dev/vda` (`commonConfig.bootEFI = false`) |
| `wisp` | Headless server | none | `serverProfile` (`commonConfig`, not `commonDesktop`); lid/suspend disabled |
| `live-iso` | ISO | sway (no DM) | Plain `nixosSystem`, not a den host; built with `nix build .#iso`. Installer session, see below |

**The GTNH Minecraft server runs on `vps`** (Contabo, Debian 13), reached with `ssh vps` (as root). It is **not** managed by this flake (there is no server module here any more), so check its status on the VPS itself. nomad pulls its world backups hourly into `~/backups/gtnh` (`homeManager.gtnhBackup`, `programs/gaming/minecraft-gtnh/backup.nix`), using `~/.ssh/gtnh_backup`, a key the VPS restricts to read-only rsync of `/var/lib/gtnh/backups`.

Each host sets `systemConstants.system = { host; type; }` (`type` ∈ laptop/desktop/server; `host` is a free string). Every host imports a profile, which sets `type` and forwards the HM copy, so a host sets only `host` (and its own `system.stateVersion`). Downstream modules branch on it (e.g. `isLaptop`, the per-host `rebuild` alias, TLP enabled only on laptops).

## Commands

```bash
rebuild                                   # alias → nh os switch ~/dotfiles#<host>
nh os switch ~/dotfiles#nomad             # same, explicit (aliases don't load in non-interactive shells / `!` commands)
nix flake check --no-build                # evaluate every host — fastest regression check after refactors
nix build .#nixosConfigurations.forge.config.system.build.toplevel   # build without switching
nix eval .#nixosConfigurations.nomad.config.<option.path>            # inspect a single resolved option
nix build .#iso                           # live installer ISO
build-iso                                 # same, copied to /var/lib/libvirt/images/nixos-live.iso (virtManager hosts)
nix flake update                          # bump inputs
nixfmt <file>
```

There are no tests; evaluation (`nix flake check --no-build`) is the check.

## Nix Architecture

`flake.nix` is a one-liner: `flake-parts.lib.mkFlake … (import-tree ./nix/modules)`. Every `.nix` file under `nix/modules/` is auto-imported as a flake-parts module (dendritic pattern). There is no central import list — **a new file is live as soon as it's `git add`ed**.

- Files never contain plain NixOS/HM modules directly. They define named modules: `flake.modules.nixos.<name>`, `flake.modules.homeManager.<name>`, or `flake.modules.generic.<name>` (usable in both layers, e.g. `systemConstants`, `theme`). One file may define several types under the same name (e.g. `swayfx` has both `nixos` and `homeManager`), and several files may contribute to the same name — they merge (e.g. `programs/swayfx/*.nix` all define `homeManager.swayfx`; every theme file defines `generic.theme`).
- Consumers import by name: `imports = with inputs.self.modules.nixos; [ commonDesktop swayfxStack ];`.
- `flake-parts []` in a directory name is only a label for the core flake-parts setup. import-tree skips nothing but paths containing `/_` (and non-`.nix` files); bracketed names are imported like any other.
- `flake.nix` is maintained by hand (flake-file is not used). den is wired in with `inputs.den.flakeModule` in `dendritic-tools.nix`.

**Host wiring via `den`:** `hosts/topology.nix` registers `den.hosts.x86_64-linux.<host>`; each host file defines `den.aspects.<host>.nixos`. The names must match exactly — a mismatch silently applies nothing and NixOS fails with "boot loader not configured". Each host file sets `system.stateVersion` itself (it records the install release; never change it for an existing host). Home Manager comes from the profile; user config goes in `home-manager.users.erik`, shared HM modules via `home-manager.sharedModules`.

**Layering for desktop hosts:**
- `commonConfig` (`hosts/common/nixos/common-nixos.nix`): base system, nix settings, TLP, systemd-boot (1 s menu timeout) with a systemd initrd on EFI hosts, dbus-broker, journald capped at 500M, and key-only OpenSSH (the authorized key for `erik` lives here; password login is disabled; `AllowUsers erik`; port 22 closed on laptops). `erik` is a nix trusted user except on servers. It imports `nixDaemon` (`nix/daemon.nix`: batch CPU scheduling for builds, weekly store optimise, the nix-community cache) and `nixos.nh` (system-wide `nh clean`, which prunes system generations).
- `memory` (`services/memory.nix`): zram plus zram sysctls (swappiness 180 etc.) and earlyoom. Imported by `commonDesktop` and `serverProfile`. The disk swap partitions stay because hibernate uses them. Use earlyoom, not systemd-oomd user slices: under LightDM, sway shares a session scope with its apps, so oomd would kill the whole desktop. earlyoom's `--avoid`/`--prefer` regexes match `/proc/<pid>/comm` (15 chars; wrapped binaries appear as `.<name>-wrapped`). earlyoom honours only one `--avoid`, so the avoid regex is joined from the list option `memory.earlyoomAvoid`; modules append to it (EXWM adds Emacs and X).
- `commonDesktop` (`common-desktop.nix`): imports `commonConfig`, `memory` and `devTools` (compilers, python, nixfmt; kept off servers); X server/xkb (which also enables **LightDM**), the `video` group, Thunar with gvfs/udisks2/tumbler, fwupd, CUPS + avahi, and HM `sharedModules` = nmtui + desktopApps + vpn. alacritty comes with each WM stack except EXWM's, which uses vterm. `programs/gtk/lightdm.nix` also contributes to it (greeter theme).
- `commonHome` (`hosts/common/home-manager/common-home.nix`): imports `generic.systemConstants` + `generic.theme`, emacs, mozillaShared + librewolf + firefox, bash, nh, ssh, vnc; enables git; sets `_module.args.isLaptop`.
- **Profiles** (`hosts/common/nixos/profiles.nix`): `mkProfile` owns everything per-user: the home-manager NixOS module, `useGlobalPkgs`/`useUserPackages`, `users.users.erik`, the `nixpkgsOverlays` module (`nix/overlays.nix`, the one overlay list), claude-code, the `commonHome` sharedModule, `systemConstants.system.type`, and forwarding `systemConstants.system` to HM. Profiles: `laptopProfile` and `desktopProfile` (commonDesktop + swayfxStack + pulseaudio), `laptopBaseProfile` and `desktopBaseProfile` (the same without a WM stack; forge adds i3Stack), `vmProfile` (xfceStack + qemu guest agents), `serverProfile` (commonConfig + memory). Every host uses one. Profile names must stay plain modules, because `install-host` generates `${type}Profile` imports. Don't also import `inputs.home-manager.nixosModules.home-manager` in a host.
- Stacks (`stacks/*-stack.nix`) bundle a WM's NixOS side + HM side. A stack's `nixos` module adds its HM half through `home-manager.sharedModules`, so hosts only import the NixOS stack. `hyprlandStack` exists but no host imports it. Wayland bits shared by sway and Hyprland (packages, screenshots, emacs-pgtk) live in `waylandBase`. A host gets one WM stack: `uiHelpers` and `swayBindings` set `_module.args` and can't be imported twice.
- **EXWM** (`exwmStack`, `programs/exwm/`): Emacs as the X window manager, with sway's binds, menus in Emacs and an Emacs tab bar instead of waybar. LightDM runs `exwm-session`, which starts the regular Emacs (`programs.emacs` plus `elpaPackages.exwm`) with `-l ~/.emacs.d/exwm/init.el`, after the normal init. The elisp lives in `nix/assets/exwm/`; nix only writes data to the generated `my-exwm-nix.el` (`keybindings.nix` translates `swayBindingsData`, `exwm.nix` adds window rules from `wmWindowRules`' `exwm` criteria and bar settings). `nix/assets/emacs.d` knows nothing about EXWM. Global keys are super keys only; X windows run in line-mode (`C-c C-k` to char-mode, `s-<escape>` back), and terminals are vterm buffers (sway's `exec alacritty` bind maps to vterm; no alacritty on EXWM hosts). Under EXWM the Emacs daemon doesn't autostart (the WM Emacs runs the server), and easysession uses a separate `exwm` session without frame restore.

**Module arguments injected via `_module.args`** (don't look for them in nixpkgs):
- `pkgsUnstable`: nixpkgs-unstable, from `system-constants/system-constants.nix`, instantiated once per system for the whole flake. Available wherever `systemConstants` is imported.
- `isLaptop`: from `commonHome`.
- From `programs/helpers.nix` (HM module `uiHelpers`, which also installs the nerd font): `mkColors`, `mkScreenshot`, `waylandScreenshots`, `hexToRgba`, `hexToHyprRgb`, `mkModeNotif`, and the i3/sway shared pieces `mkWmColors` (title bar colors from the theme), `wmWindowRules` (one rule list with per-WM criteria), `mkWmModes` (modal binds + key notification from a modes attrset) and `mkPolkitAgent` (polkit-gnome user service bound to a target).
- `swayBindingsData`: from `homeManager.swayBindings` (`programs/swayfx/bindings-data.nix`, imported by `swayfx` and `exwm`). This is the **single source of truth** for sway keybindings. `keybindings.nix`, `modes.nix` and the `sway-help` cheatsheet in `packages.nix` all derive from it, so edit binds there. `programs/exwm/keybindings.nix` translates every action to EXWM and throws on one it doesn't know, so a new action needs a mapping there (the `exwm-eval` check catches it). The binds are set at normal priority, which drops all of HM's default sway binds, so a bind missing from the data doesn't exist.

**Theme system** (`system-constants/theme.nix` + `themes/*.nix`; onedark, catppuccin, gruvbox, tokyonight, ef-bio (the Emacs theme's palette)): `selectedTheme` is an enum built from the file names in `themes/`, so adding a theme is just adding `themes/<name>.nix` (setting `config.theme` under `mkIf (selectedTheme == "<name>")`). `config.theme` is a submodule: free-form `name = "#rrggbb"` colors plus typed knobs `accent` (default `blue`), `urgentForeground` (text on red title bars, default `background`), `rounding`, `gaps`, `opacity`, `blur`, `dimInactive` (sway dimming, default 0.1 when `opacity < 1`), `fontFamily`. Text on `accent` uses `background`. UI modules read it as `let c = config.theme; in …`. An assertion lists any of the 21 required palette keys a theme is missing. GTK CSS doesn't accept `alpha(#hex, a)`; use `hexToRgba`.

**Custom packages:** `nix/packages/<name>/package.nix` (geforcenow, irealpro, update-debs, claude-usage) is auto-discovered by pkgs-by-name and exposed as `pkgs.local.<name>` via `flake.overlays.default`. Every profile and the live ISO get it through `nixos.nixpkgsOverlays`.

Packages fetched from an unversioned "latest" URL (irealpro) keep `version`/`url`/`hash`/`etag` in a sibling `source.json` that `package.nix` reads with `lib.importJSON`. `nix run .#update-debs` refreshes every `nix/packages/*/source.json` (a failing package doesn't stop the others; the exit code is non-zero), and `.github/workflows/update-debs.yml` runs it daily, builds what changed and opens a PR. On a hash mismatch, run `nix run .#update-debs` or merge that PR.

**CI:** `.github/workflows/eval.yml` runs `nix flake check --no-build` on every push and PR. CI has no git-crypt key, so it swaps the encrypted `hosts.nix` for `.github/ci/hosts-stub.nix`. A module that references a new host by name (like nomad's `hass-vm`) needs that key in the stub too. Actions are pinned to commit SHAs; dependabot proposes updates. `checks.x86_64-linux.exwm-eval` (`programs/exwm/check.nix`) is an eval-only system with `exwmStack`, so the check evaluates EXWM although no host uses it; build it only with `--no-build`.

## Installing a host

`nix build .#iso` → boot it. It autologins `nixos` into sway (catppuccin, firefox, emacs, claude-code) and runs `install-host` (`hosts/live-iso/install-host.nix`, script in `nix/assets/install-host.sh`). The script clones the repo and unlocks git-crypt. It then offers either reinstalling a host from `topology.nix` or creating a new laptop/desktop/server/vm host, and partitions by firmware (UEFI → ESP + systemd-boot, BIOS → bios_grub + GRUB). It refuses a locked repo, the installer medium and disks in use, and for a reinstall it first checks that the host evaluates and that its `commonConfig.bootEFI` matches the firmware mode. For a new host it writes `hosts/<name>/<name>.nix` (one profile import plus `system.stateVersion` from the flake's nixpkgs) and a verbatim `_hardware-configuration.nix`, and registers the host in `topology.nix` above the `# install-host inserts new hosts above this line` anchor (keep that line). It then runs `nixos-install`, copies the clone to `/home/erik/dotfiles`, and sets erik's password. import-tree skips paths containing `/_`, so `_`-prefixed files can hold plain NixOS modules.

## Gotchas

- **Audio is PulseAudio on all desktop hosts** (`commonDesktop` sets `services.pipewire.enable = false`; each desktop host imports the `pulseaudio` module, and `bluetooth` only adds `extraConfig` to it). As a result, `xdg-desktop-portal-wlr` is gated on PipeWire in `programs/swayfx/swayfx.nix`, because without PipeWire it crash-loops and stalls the portal (waybar then hangs on startup). It also means Wayland screen sharing doesn't work.
- **Under EXWM, Emacs is the session**: an Emacs crash or `kill-emacs` drops back to the LightDM greeter. EXWM needs an X11 Emacs, so `exwmStack` can't share a host with a Wayland stack (an assertion checks that `programs.emacs.package` isn't pgtk). `nix-add-package` and `claude-prompt` (`homeManager.claudeLaunchers`) ask with wofi and open a floating alacritty (sway). EXWM asks in the minibuffer, gets the targets and the prompt from `nix-add-package --list-targets` / `--print-prompt`, and runs claude in vterm. The scripts take alacritty from PATH (the stack installs it), not runtimeInputs.
- **Sway hosts start sway from LightDM**, not from the `exec sway` on tty1 in the swayfx module's `bash.profileExtra` (kept as a fallback). Disabling the display manager kills the running session during `switch`.
- **Sway session services bind to `sway-session.target`** (`wayland.systemd.target` in `homeManager.swayfx`), not `graphical-session.target`. NixOS starts `nixos-fake-graphical-session.target` for sway and never stops it, so anything on `graphical-session.target` starts before `WAYLAND_DISPLAY` exists and outlives the session. HM's default sway `extraCommands` start and stop `sway-session.target`; don't override that list.
- `gaming` imports the `geforcenow` NixOS module (flatpak + a oneshot install service), so any host that imports `gaming` gets it. It also sets `linuxPackages_latest`, nix-ld, Steam (its LAN ports open only on non-laptops) and wine. Intel GPU settings (i915 params, `hardware.intelgpu`, VA-API, and the matching Firefox/LibreWolf video-decode prefs) live in `nomad.nix`. nomad runs `throttled` (from nixos-hardware) and has thermald off on purpose, because the two fight over the CPU power limits.
- Firefox and LibreWolf share search engines, base prefs and extensions through the `mozillaShared` module arg (`browsers/mozilla-shared.nix`); edit shared bits there.
- `homeManager.nh` points `programs.nh.flake` at `~/dotfiles`, so a bare `nh os switch` uses the working tree.
- To override a value nixpkgs sets at normal priority (e.g. `xdg.portal.wlr.enable` from the sway module), use `lib.mkForce`; a plain assignment will error with conflicting definitions.

## Assets (`nix/assets/`)

- `emacs.d/`: based on minimal-emacs.d, using straight.el + use-package. Customisation lives in `post-init.el`; `pre-init.el` bootstraps straight. Linked into `~/.emacs.d/` by `programs/emacs/emacs.nix` via `home.file`. Wayland hosts get `emacs-pgtk` via `homeManager.waylandBase`.
- `wallpapers/`: default `systemConstants.wallpaper`.

forge (i3) is not in active use. Its i3 session starts from LightDM via a `home-manager` session that runs the HM-generated `~/.hm-xsession` (`nixos.i3` + `xsession.enable` in `homeManager.i3`).

## Secrets (`nix/secrets/`)

The repo is public, so private data goes in `nix/secrets/`, which sits outside `nix/modules/`.
- `hosts.nix`: the LAN inventory (`{ <name> = { ip; user ? "erik"; vnc ? null; }; }`; `vnc` is an out-of-band console used by the `vnc <host>` command in `shell/vnc.nix`). It's **git-crypt encrypted**, so the repo must be unlocked (`git-crypt unlock ~/.config/git-crypt/dotfiles.key`) or eval fails. It's exposed as `systemConstants.network.hosts`, and `homeManager.ssh` (`shell/ssh.nix`) turns every entry into an ssh `matchBlock`, so use `ssh <host>` (e.g. `ssh wisp`) to reach hosts. Read the file for IPs. Never hardcode a LAN IP in a module.
- Encryption is driven by `nix/secrets/.gitattributes`, which encrypts **every** file in the directory except the ones it lists explicitly (`.gitattributes`, `.sops.yaml`, `secrets.yaml`). After adding a file, confirm with `git-crypt status nix/secrets`. git-crypt is for data that may end up in the world-readable nix store (it does: modules import `hosts.nix`); real secrets go in sops.
- Runtime secrets (passwords, tokens) go in `secrets.yaml` via **sops-nix** (`nix/modules/nix/sops.nix`, imported by `commonConfig`). It stays inactive until `secrets.yaml` exists. Recipients are in `nix/secrets/.sops.yaml` (the admin key plus host age keys from `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`; only nomad has one so far, so add a host's key before giving it secrets), and `sops` must run from `nix/secrets/`. Declare `sops.secrets.<name>` and read `config.sops.secrets.<name>.path`. The values never enter the nix store.

## Mail

Desktop hosts use the `protonmail-desktop` app (installed, not autostarted). There is no mbsync/notmuch setup.
