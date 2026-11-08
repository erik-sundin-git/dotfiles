"""install-host: reinstall a host from the dotfiles flake, or create a new one.

The wizard (flow.py) runs in urwid and changes nothing but the clone; the
install (install.py) runs in the plain terminal so nix's output scrolls and
can be copied. Everything is logged to /tmp/install-host/install.log.
"""

from __future__ import annotations

import argparse
import os
import shutil
import signal
import socket
import sys
from pathlib import Path

from . import flow, install, ui, util
from .repo import DEFAULT_DIR, Changes, Repo
from .spec import HostSpec, SchemaMismatch, validate

# From the ISO's system, not nixpkgs (see package.nix)
SYSTEM_TOOLS = ["nix", "nixos-install", "nixos-enter", "nixos-generate-config"]


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="install-host", description=__doc__.splitlines()[0])
    p.add_argument("--dry-run", action="store_true", help="stop after evaluating; no root, no disk changes, clone rolled back")
    p.add_argument("--answers", type=Path, help="HostSpec JSON (as saved to /tmp/install-host/answers.json); skips the wizard")
    p.add_argument("--repo", type=Path, help=f"use this dotfiles checkout instead of cloning to {DEFAULT_DIR}")
    p.add_argument("--skip-preflight", action="store_true", help="skip the network and terminal checks")
    p.add_argument("--yes-wipe", metavar="SERIAL", help="with --answers: skip the typed confirmation for the disk with this serial")
    return p.parse_args(argv)


def become_root(argv: list[str]) -> None:
    if os.geteuid() == 0:
        return
    # The Python wrapper leaves a bare name in argv[0]; package.nix sets this
    exe = os.environ.get("INSTALL_HOST_BIN") or shutil.which(sys.argv[0]) or sys.argv[0]
    os.execvp("sudo", ["sudo", "--preserve-env=TERM,LANG,LC_ALL,SSH_CONNECTION,TMUX", exe, *argv])


class Interrupted(KeyboardInterrupt):
    pass


def _interrupted(signum: int, _frame: object) -> None:
    raise Interrupted(f"signal {signum}")


def preflight() -> None:
    cols, rows = shutil.get_terminal_size()
    if cols < ui.MIN_COLS or rows < ui.MIN_ROWS:
        sys.exit(f"The terminal is {cols}x{rows}; install-host needs at least {ui.MIN_COLS}x{ui.MIN_ROWS}.")
    if os.environ.get("SSH_CONNECTION") and not os.environ.get("TMUX"):
        print("Running over ssh outside tmux: a dropped connection kills the install midway.")
        if input("Continue anyway? [y/N] ").strip().lower() != "y":
            sys.exit(1)
    while not _online():
        print("No network (github.com isn't reachable). Opening nmtui to connect...")
        print("(Broadcom Wi-Fi chips need firmware the ISO lacks; use ethernet or a USB adapter.)")
        input("Press Enter to open nmtui.")
        util.interactive(["nmtui"])
        if not _online() and input("Still offline. Try again? [Y/n] ").strip().lower() == "n":
            sys.exit(1)


def _online() -> bool:
    try:
        socket.create_connection(("github.com", 443), timeout=5).close()
        return True
    except OSError:
        return False


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    args = parse_args(argv)
    if not args.dry_run:
        become_root(argv)
        missing = [t for t in SYSTEM_TOOLS if not shutil.which(t)]
        if missing:
            sys.exit(f"Missing {', '.join(missing)}: run install-host on the NixOS live ISO.")

    signal.signal(signal.SIGTERM, _interrupted)
    signal.signal(signal.SIGHUP, _interrupted)
    util.STATE_DIR.mkdir(parents=True, exist_ok=True)
    util.log(f"--- install-host {' '.join(argv)}")

    if not args.skip_preflight:
        preflight()

    if args.repo:
        repo = Repo(args.repo.resolve())
    else:
        print(f"Getting the dotfiles ({DEFAULT_DIR})...")
        try:
            repo = Repo.clone()
        except util.CommandFailed as e:
            sys.exit(f"Clone failed:\n{e.output}")

    if not flow.unlock(repo):
        return 1

    try:
        opts = ui.spinner("Starting", "Reading the installer options from the flake", repo.options)
        ctx = ui.spinner("Starting", "Detecting hardware", lambda: flow.Context.detect(repo, opts))
    except SchemaMismatch as e:
        sys.exit(str(e))
    except util.CommandFailed as e:
        sys.exit(f"Can't evaluate the flake's installer data:\n{e.output}")

    changes = Changes(repo)
    started = False
    try:
        if args.answers:
            spec = HostSpec.from_json(args.answers.read_text())
            errors = validate(spec, opts, repo.hosts(), repo.host_dirs())
            if errors:
                sys.exit("The answers don't validate:\n  " + "\n  ".join(errors))
            if args.yes_wipe is not None and not (args.yes_wipe and spec.disk_serial):
                sys.exit("--yes-wipe needs the disk's serial, and this disk has none: confirm by typing instead.")
            confirm = not args.dry_run and args.yes_wipe != spec.disk_serial
            spec = flow.run(ctx, spec, changes, confirm=confirm)
        else:
            resumed = None if args.dry_run else flow.resume_choice(repo)
            spec = flow.run(ctx, resumed, changes, confirm=not args.dry_run)
        if spec is None:
            return 1

        if args.dry_run:
            print(f"Dry run: {spec.host} evaluates. Answers: {util.ANSWERS_FILE}")
            return 0

        install.revalidate(spec)
        uses_disko = spec.new or repo.host_uses_disko(spec.host)
        # From here on the disk is being erased: keep the host files so a
        # re-run can offer them (resume) instead of rolling them back
        changes.keep = True
        started = True
        install.wipe_and_mount(spec, repo, uses_disko)
        if not uses_disko:
            install.patch_hardware_nix(spec, repo)
        pubkey = install.host_ssh_key(spec.host)
        install.nixos_install(spec, repo)
        install.finish(spec, repo)
        install.done(spec, pubkey)
        util.ANSWERS_FILE.unlink(missing_ok=True)
        return 0
    except install.Aborted as e:
        print(f"\nStopped: {e}")
        return 1
    except util.CommandFailed as e:
        print(f"\n{e}\n{e.output}")
        return 1
    except KeyboardInterrupt:
        print("\nInterrupted.")
        return 130
    finally:
        changes.rollback()
        if started and not (install.MNT / "var/log/install-host.log").exists():
            install.unmount()
            print(f"Unmounted /mnt. The log is {util.LOG_FILE}; run install-host again to resume.")


if __name__ == "__main__":
    sys.exit(main())
