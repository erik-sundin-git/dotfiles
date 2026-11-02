"""The dotfiles clone the host is installed from."""

from __future__ import annotations

import glob
import json
import re
import shutil
from pathlib import Path

from . import util
from .spec import Options

REPO_URL = "https://github.com/erik-sundin-git/dotfiles.git"
DEFAULT_DIR = Path("/tmp/dotfiles")
HOSTS = Path("nix/modules/hosts")

# Where a git-crypt key usually is: copied over ssh, or on a USB stick
KEY_GLOBS = [
    "/home/nixos/*.key",
    "/home/nixos/*/*.key",
    "/run/media/*/*/*.key",
    "/run/media/*/*/*/*.key",
    "/root/*.key",
]


def find_keys() -> list[str]:
    found = sorted({p for g in KEY_GLOBS for p in glob.glob(g)})
    return sorted(found, key=lambda p: not p.endswith("dotfiles.key"))


class Repo:
    def __init__(self, root: Path):
        self.root = root
        self.hosts_dir = root / HOSTS
        self.topology = self.hosts_dir / "topology.nix"

    def git(self, *args: str, check: bool = True) -> str:
        return util.capture(["git", "-C", str(self.root), *args], check=check)

    @classmethod
    def clone(cls, dest: Path = DEFAULT_DIR) -> Repo:
        """Reuse an earlier clone (it may hold a host from a failed run);
        otherwise clone next to it and rename, so a dropped connection never
        leaves a half clone behind."""
        if (dest / ".git").is_dir() and util.ok(["git", "-C", str(dest), "rev-parse", "HEAD"]):
            return cls(dest)
        partial = dest.with_name(dest.name + ".partial")
        shutil.rmtree(partial, ignore_errors=True)
        util.capture(["git", "clone", "--depth", "1", REPO_URL, str(partial)])
        shutil.rmtree(dest, ignore_errors=True)
        partial.rename(dest)
        return cls(dest)

    # ── git-crypt ─────────────────────────────────────────────────────────

    def locked(self) -> bool:
        # nix/secrets/hosts.nix is evaluated by every host
        head = (self.root / "nix/secrets/hosts.nix").read_bytes()[:10].replace(b"\0", b"")
        return head.startswith(b"GITCRYPT")

    def unlock(self, key: str) -> None:
        self.git("crypt", "unlock", key)

    def export_key(self, dest: Path) -> None:
        dest.parent.mkdir(parents=True, exist_ok=True)
        self.git("crypt", "export-key", str(dest))
        dest.chmod(0o600)

    # ── Hosts ─────────────────────────────────────────────────────────────

    def hosts(self) -> list[str]:
        return re.findall(r"den\.hosts\.x86_64-linux\.([a-z0-9-]+)", self.topology.read_text())

    def host_dirs(self) -> list[str]:
        return [p.name for p in self.hosts_dir.iterdir() if p.is_dir()]

    def host_dir(self, host: str) -> Path:
        return self.hosts_dir / host

    def is_sops_recipient(self, host: str) -> bool:
        sops = self.root / "nix/secrets/.sops.yaml"
        return sops.is_file() and re.search(rf"\b{re.escape(host)}\b", sops.read_text()) is not None

    def dirty_hosts(self) -> list[str]:
        """Host files changed by an earlier run that never got committed."""
        out = self.git("status", "--porcelain", "--", str(HOSTS))
        return [line[3:] for line in out.splitlines() if line.strip()]

    def discard_host_changes(self) -> None:
        """Back to HEAD under nix/modules/hosts only, never repo-wide."""
        self.git("reset", "-q", "--", str(HOSTS))
        self.git("checkout", "HEAD", "--", str(HOSTS))
        self.git("clean", "-fdq", "--", str(HOSTS))

    # ── Nix ───────────────────────────────────────────────────────────────

    def nix(self, attr: str, *args: str) -> str:
        return util.capture(
            ["nix", "eval", "--option", "accept-flake-config", "false", f"{self.root}#{attr}", *args]
        )

    def options(self) -> Options:
        return Options(json.loads(self.nix("installer", "--json")))

    def eval_host(self, host: str) -> None:
        """Raises util.CommandFailed with nix's error on failure."""
        self.nix(f"nixosConfigurations.{host}.config.system.build.toplevel.drvPath", "--raw")

    def host_efi(self, host: str) -> bool:
        return json.loads(self.nix(f"nixosConfigurations.{host}.config.commonConfig.bootEFI", "--json"))

    def host_uses_disko(self, host: str) -> bool:
        return json.loads(
            self.nix(f"nixosConfigurations.{host}.config", "--json", "--apply", "c: c ? diskLayout")
        )

    def disk_layout(self, device: str, swap_gib: int, efi: bool) -> dict:
        """lib.diskLayout's disko.devices for a host that doesn't import it."""
        expr = (
            f'f: f {{ device = "{device}"; swapGiB = {swap_gib}; '
            f"efi = {'true' if efi else 'false'}; }}"
        )
        return json.loads(self.nix("lib.diskLayout", "--json", "--apply", expr))


class Changes:
    """Files the installer writes into the clone. They're git-added (the flake
    only sees tracked files) and rolled back unless the install went ahead,
    so Back, a failed evaluation or --dry-run leave the clone as it was."""

    def __init__(self, repo: Repo):
        self.repo = repo
        self.modified: list[Path] = []  # tracked files we changed
        self.created: list[Path] = []  # new files and directories
        self.keep = False

    def write(self, path: Path, text: str) -> None:
        tracked = util.ok(["git", "-C", str(self.repo.root), "ls-files", "--error-unmatch", str(path)])
        if tracked:
            if path not in self.modified:
                self.modified.append(path)
        else:
            top = path.parent
            while not top.parent.exists():
                top = top.parent
            new = top if not top.exists() else path
            if new not in self.created:
                self.created.append(new)
            path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        self.repo.git("add", str(path))

    def rollback(self) -> None:
        if self.keep:
            return
        paths = [str(p) for p in self.modified + self.created]
        if paths:
            self.repo.git("reset", "-q", "--", *paths, check=False)
        if self.modified:
            self.repo.git("checkout", "HEAD", "--", *map(str, self.modified), check=False)
        for p in self.created:
            if p.is_dir():
                shutil.rmtree(p)
            else:
                p.unlink(missing_ok=True)
        self.modified.clear()
        self.created.clear()
