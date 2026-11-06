# Repository Guidelines

## Project Structure & Module Organization

This repository is a Nix flake for several NixOS hosts, with Home Manager integrated through NixOS. `flake.nix` imports `nix/modules/` automatically using `import-tree`; host definitions are in `nix/modules/hosts/`, reusable system and user modules in `nix/modules/`, packages in `nix/packages/`, and referenced non-Nix files in `nix/assets/`. Keep assets outside `nix/modules/` so import-tree does not treat them as modules. Installer tests live in `nix/packages/install-host/tests/`. Private or encrypted configuration belongs in `nix/secrets/`.

## Build, Test, and Development Commands

- `nix flake check --no-build` evaluates all flake checks and host configurations; run it after module or host changes.
- `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` builds a host without switching it.
- `nix build .#install-host` builds the installer and runs its pytest suite.
- `nix run .#install-host -- --dry-run` exercises the installer flow without installing a system.
- `nixfmt <file>` formats a Nix file. `nix build .#iso` builds the live installer ISO.

## Coding Style & Naming Conventions

Follow nearby Nix style: two-space indentation, attribute sets for related options, and descriptive lower-camel-case names for module attributes. Define reusable modules as `flake.modules.nixos.<name>`, `flake.modules.homeManager.<name>`, or `flake.modules.generic.<name>`; host files wire modules together rather than duplicating shared settings. Python code and tests are under `nix/packages/install-host/`; tests use `test_*.py` names. Keep host-specific values in the corresponding host module and avoid hardcoding private network details.

## Testing Guidelines

Run `nix flake check --no-build` for Nix evaluation changes and `nix build .#install-host` for installer changes. CI runs both. The installer tests use pytest; there is no repository-wide test or coverage threshold. For host behavior changes, build the affected host configuration before switching it.

## Commit & Pull Request Guidelines

Recent commits use short, imperative subjects, often prefixed by the affected area (for example, `mail: fix inbox tagging`). Keep commits focused. Pull requests should explain the user-visible change, list relevant evaluation or build commands and results, and mention any host-specific impact. Do not add `Co-Authored-By` trailers.

## Secrets & Configuration

Never commit plaintext credentials, tokens, or private keys. `nix/secrets/` uses git-crypt for designated files; runtime secrets belong in sops-nix. Check `git-crypt status nix/secrets` when changing files there, and do not hardcode LAN addresses in modules.
