---
description: Evaluate every host and run deadnix, as CI's eval.yml does
argument-hint: "[fix]"
allowed-tools: Bash(git status *), Bash(git-crypt status *), Bash(nix flake check --no-build*), Bash(nix build --no-link .#checks.x86_64-linux.deadnix*)
---
Run this repo's checks in order and stop at the first that fails:

1. `git status --short`: list any untracked `.nix` file under `nix/`. The flake
   can't see it, so evaluation fails with "undefined variable". Report it
   first.
2. If `git-crypt status nix/secrets` shows the secrets encrypted, the repo is
   locked: say so and stop. Don't unlock it.
3. `nix flake check --no-build` (every host, plus the installer-* systems).
4. `nix build --no-link .#checks.x86_64-linux.deadnix`.

Report each step as passed or failed. For a failure, quote the relevant
error lines and find the module that causes it (file:line). If the argument
is `fix` ($ARGUMENTS), fix it and run the checks again; otherwise only
propose the fix.
