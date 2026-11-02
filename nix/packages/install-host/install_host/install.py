"""The destructive part, run in the plain terminal after the TUI: wipe and
partition with disko, install, copy the dotfiles, set erik's password."""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

from . import nixgen, system, util
from .repo import Repo
from .spec import HostSpec

MNT = Path("/mnt")
PARTLABEL = Path("/dev/disk/by-partlabel")  # disko names them disk-main-<part>


class Aborted(Exception):
    pass


def revalidate(spec: HostSpec) -> None:
    """Right before wiping: the chosen disk is still the same, unused disk."""
    disk = system.resolve(spec.disk)
    if disk is None:
        raise Aborted(f"{spec.disk} is gone.")
    if disk.size != spec.disk_size or disk.serial != spec.disk_serial:
        raise Aborted(f"{spec.disk} is now a different disk ({disk.label()}).")
    if disk.installer:
        raise Aborted(f"{disk.path} is the installer medium.")
    if disk.in_use:
        raise Aborted(f"{disk.path} is in use: {', '.join(disk.in_use)}")


def wipe_and_mount(spec: HostSpec, repo: Repo, uses_disko: bool) -> None:
    disk_path = system.resolve(spec.disk).path  # type: ignore[union-attr]
    for cmd in system.teardown_commands(system.lsblk_tree(), disk_path):
        util.run(cmd, check=False)

    disko = ["disko", "--mode", "destroy,format,mount", "--yes-wipe-all-disks"]
    if uses_disko:
        util.run(disko + ["--flake", f"{repo.root}#{spec.host}"])
    else:
        # A hand-written host: same layout, from lib.diskLayout
        layout = repo.disk_layout(spec.disk, spec.swap_gib, spec.efi)
        (util.STATE_DIR / "disko.json").write_text(json.dumps(layout))
        config = util.STATE_DIR / "disko.nix"
        config.write_text("{ disko.devices = builtins.fromJSON (builtins.readFile ./disko.json); }\n")
        util.run(disko + [str(config)])
    util.run(["udevadm", "settle"])


def patch_hardware_nix(spec: HostSpec, repo: Repo) -> None:
    """Point a hand-written hardware.nix at the new filesystems."""
    hw = repo.host_dir(spec.host) / "hardware.nix"
    parts = {"root": "root", "swap": "swap", "boot": "ESP"}
    new = {
        what: util.capture(["blkid", "-s", "UUID", "-o", "value", str(PARTLABEL / f"disk-main-{parts[what]}")]).strip()
        for what in nixgen.uuid_parts(spec.efi)
    }
    hw.write_text(nixgen.patch_uuids(hw.read_text(), new))
    repo.git("add", str(hw))
    util.log(f"hardware.nix UUIDs: {new}")


def host_ssh_key(host: str) -> Path:
    """Made now (sshd would only make it on first boot), so the sops age key
    can be printed before the first boot."""
    key = MNT / "etc/ssh/ssh_host_ed25519_key"
    if not key.exists():
        key.parent.mkdir(parents=True, exist_ok=True)
        util.run(["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key), "-C", f"root@{host}"])
    return key.with_suffix(".pub")


def ask(prompt: str, choices: str) -> str:
    while True:
        answer = input(f"{prompt} ").strip().lower()[:1]
        if answer in choices:
            return answer


def nixos_install(spec: HostSpec, repo: Repo) -> None:
    cmd = ["nixos-install", "--no-root-passwd", "-L", "--flake", f"{repo.root}#{spec.host}"]
    while util.run(cmd, check=False) != 0:
        print(f"\nnixos-install failed; the log is in {util.LOG_FILE}.")
        print("The disk stays mounted at /mnt, so a retry doesn't repartition.")
        choice = ask("[r]etry, open a [s]hell, or [a]bort?", "rsa")
        if choice == "a":
            raise Aborted("nixos-install failed.")
        if choice == "s":
            print("Exit the shell to come back here.")
            util.interactive([shutil.which("bash") or "/bin/sh"])


def finish(spec: HostSpec, repo: Repo) -> None:
    home = MNT / "home/erik"
    home.mkdir(parents=True, exist_ok=True)
    home.chmod(0o700)
    dest = home / "dotfiles"
    shutil.rmtree(dest, ignore_errors=True)
    util.run(["cp", "-a", str(repo.root), str(dest)])
    # Every rebuild evaluates the git-crypt encrypted hosts.nix
    repo.export_key(home / ".config/git-crypt/dotfiles.key")
    # erik only exists inside the new system
    util.run(["nixos-enter", "--root", str(MNT), "-c", "chown -R erik:users /home/erik"])

    print("\nSet a password for erik (ssh is key-only, and there's no root password):")
    while util.interactive(["nixos-enter", "--root", str(MNT), "-c", "passwd erik"]) != 0:
        print("Try again.")

    logs = MNT / "var/log"
    logs.mkdir(parents=True, exist_ok=True)
    shutil.copy(util.LOG_FILE, logs / "install-host.log")


def unmount() -> None:
    subprocess.run(["umount", "-R", str(MNT)], capture_output=True)
    swap = PARTLABEL / "disk-main-swap"
    if swap.exists():
        subprocess.run(["swapoff", str(swap)], capture_output=True)


def network_summary() -> str:
    """For the hosts.nix entry: addresses as seen from the ISO."""
    lines = []
    for iface in sorted(Path("/sys/class/net").iterdir()):
        if iface.name == "lo":
            continue
        out = util.capture(["ip", "-4", "-o", "addr", "show", "dev", iface.name, "scope", "global"], check=False)
        for line in out.splitlines():
            addr = line.split()[3].split("/")[0]
            mac = (iface / "address").read_text().strip()
            lines.append(f"{iface.name}: {addr} ({mac})")
    return "\n".join(lines)


def done(spec: HostSpec, pubkey: Path) -> None:
    print(f"\n\033[1mDone: {spec.host} is installed.\033[0m Dotfiles are in /home/erik/dotfiles.")
    print("After the first boot, commit the host changes there and push.")
    if spec.new:
        age = util.capture(["ssh-to-age"], input=pubkey.read_text(), check=False).strip()
        print("\nAdd it to nix/secrets/hosts.nix (the address may differ once installed):")
        print(network_summary() or "  (no network address)")
        print(f'  {spec.host} = {{ ip = "..."; }};')
        if age:
            print("\nIts sops age key, for nix/secrets/.sops.yaml (see CLAUDE.md, Secrets):")
            print(f"  - &{spec.host} {age}")
    print("\nReboot when ready.")
