import subprocess
from pathlib import Path

import pytest

from install_host import flow, install, system, util
from install_host.install import Aborted
from install_host.repo import HOSTS, Changes, Repo
from install_host.spec import HostSpec


def git(root: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root), "-c", "user.name=t", "-c", "user.email=t@t", *args],
        check=True, capture_output=True, text=True,
    ).stdout


@pytest.fixture
def repo(tmp_path: Path) -> Repo:
    root = tmp_path / "dotfiles"
    hosts = root / HOSTS
    (hosts / "nomad").mkdir(parents=True)
    (hosts / "topology.nix").write_text("den.hosts.x86_64-linux.nomad = { };\n")
    (hosts / "nomad/nomad.nix").write_text("old\n")
    (root / "README").write_text("other\n")
    git(root, "init", "-q")
    git(root, "add", "-A")
    git(root, "commit", "-qm", "init")
    return Repo(root)


def status(repo: Repo) -> str:
    return git(repo.root, "status", "--porcelain")


def test_changes_rollback_restores_tracked_and_removes_new(repo):
    changes = Changes(repo)
    changes.write(repo.hosts_dir / "nomad/nomad.nix", "new\n")
    changes.write(repo.hosts_dir / "fresh/fresh.nix", "x\n")
    assert "fresh/fresh.nix" in status(repo)  # git-added: the flake sees it
    changes.rollback()
    assert (repo.hosts_dir / "nomad/nomad.nix").read_text() == "old\n"
    assert not (repo.hosts_dir / "fresh").exists()
    assert status(repo) == ""


def test_changes_keep_skips_rollback(repo):
    changes = Changes(repo)
    changes.write(repo.hosts_dir / "nomad/nomad.nix", "new\n")
    changes.keep = True
    changes.rollback()
    assert (repo.hosts_dir / "nomad/nomad.nix").read_text() == "new\n"


def test_discard_host_changes_stays_under_hosts(repo):
    (repo.hosts_dir / "nomad/nomad.nix").write_text("dirty\n")
    (repo.root / "README").write_text("dirty too\n")
    repo.discard_host_changes()
    assert (repo.hosts_dir / "nomad/nomad.nix").read_text() == "old\n"
    assert (repo.root / "README").read_text() == "dirty too\n"


def test_resume_never_discards_a_user_checkout(repo, monkeypatch, tmp_path):
    # Not the installer's own clone (/tmp/dotfiles): uncommitted host work stays
    (repo.hosts_dir / "nomad/nomad.nix").write_text("my work\n")
    monkeypatch.setattr(flow.os.path, "ismount", lambda _: False)
    monkeypatch.setattr(util, "ANSWERS_FILE", tmp_path / "none.json")
    monkeypatch.setattr(flow.ui, "menu", lambda *a, **k: pytest.fail("nothing to offer"))
    assert flow.resume_choice(repo) is None
    assert (repo.hosts_dir / "nomad/nomad.nix").read_text() == "my work\n"


def disk(**kw) -> system.Disk:
    base = dict(path="/dev/sda", size=500 * 1024**3, model="SSD", serial="S1", tran="sata", removable=False)
    return system.Disk(**{**base, **kw})


def spec(**kw) -> HostSpec:
    return HostSpec(host="nomad", disk="/dev/disk/by-id/ata-SSD_S1", disk_serial="S1", disk_size=500 * 1024**3, **kw)


@pytest.mark.parametrize(
    "found, error",
    [
        (None, "is gone"),
        (disk(serial="OTHER"), "different disk"),
        (disk(size=1), "different disk"),
        (disk(installer=True), "installer medium"),
        (disk(in_use=["/mnt"]), "in use"),
    ],
)
def test_revalidate_refuses(monkeypatch, found, error):
    monkeypatch.setattr(system, "resolve", lambda _: found)
    with pytest.raises(Aborted, match=error):
        install.revalidate(spec())


def test_revalidate_accepts_the_same_disk(monkeypatch):
    monkeypatch.setattr(system, "resolve", lambda _: disk())
    install.revalidate(spec())
