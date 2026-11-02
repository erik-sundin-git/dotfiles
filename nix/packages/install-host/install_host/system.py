"""What the installer learns about the machine: firmware, DMI, PCI, disks.

Readers take a sysfs root or command output as arguments so the tests can feed
them fixtures.
"""

from __future__ import annotations

import json
import math
import os
import re
from dataclasses import dataclass, field
from pathlib import Path

from . import util

SYS = Path("/sys")

# SMBIOS chassis types for portables (laptop, notebook, sub-notebook,
# convertible, detachable, ...)
LAPTOP_CHASSIS = {8, 9, 10, 14, 30, 31, 32}

# Partition contents that mean someone's data or a volume layer is there
RISKY_FSTYPES = {
    "BitLocker",
    "ntfs",
    "crypto_LUKS",
    "LVM2_member",
    "linux_raid_member",
    "isw_raid_member",
    "ddf_raid_member",
    "zfs_member",
}


def firmware_efi(sys: Path = SYS) -> bool:
    return (sys / "firmware/efi").is_dir()


def _read(path: Path) -> str:
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def dmi(sys: Path = SYS) -> dict[str, str]:
    base = sys / "class/dmi/id"
    return {k: _read(base / k) for k in ("sys_vendor", "product_name", "product_version", "chassis_type")}


def is_vm() -> bool:
    return util.ok(["systemd-detect-virt", "--vm", "--quiet"])


def default_type(info: dict[str, str], vm: bool) -> str:
    if vm:
        return "vm"
    try:
        return "laptop" if int(info.get("chassis_type", "")) in LAPTOP_CHASSIS else "desktop"
    except ValueError:
        return "desktop"


def ram_gib(meminfo: str | None = None) -> int:
    """Physical RAM in whole GiB: MemTotal sits a little below it, so round up."""
    if meminfo is None:
        meminfo = Path("/proc/meminfo").read_text()
    kib = int(re.search(r"^MemTotal:\s+(\d+)", meminfo, re.M).group(1))  # type: ignore[union-attr]
    return max(1, math.ceil(kib / 1024 / 1024))


# ── nixos-hardware suggestions ────────────────────────────────────────────

_VENDOR_WORDS = {"dell", "inc", "lenovo", "hp", "hewlett", "packard", "asustek", "computer", "asus", "co", "ltd", "corporation", "micro", "star", "international", "system", "product", "name", "to", "be", "filled", "by", "o.e.m.", "default", "string"}


def _tokens(text: str) -> set[str]:
    words = [w for w in re.split(r"[^a-z0-9]+", text.lower()) if w]
    tokens = set(words) | {a + b for a, b in zip(words, words[1:])}
    return {t for t in tokens if t not in _VENDOR_WORDS}


def _is_model(token: str) -> bool:
    """Model numbers carry the match: t480s, 7590, x1, 840g5. A bare "15" or
    "13" (screen size) or a plain word doesn't."""
    return bool(re.search(r"\d", token)) and (len(token) >= 3 or re.search(r"[a-z]", token) is not None)


def suggest_hardware(info: dict[str, str], modules: list[str], limit: int = 6) -> list[str]:
    """nixos-hardware modules ranked by how well they match the DMI strings."""
    machine = _tokens(" ".join([info.get("product_name", ""), info.get("product_version", "")]))
    vendor = (info.get("sys_vendor", "").split() or [""])[0].lower()
    scored = []
    for name in modules:
        parts = name.split("-")
        mod = set(parts) | {a + b for a, b in zip(parts, parts[1:])}
        hits = machine & mod
        if not any(_is_model(t) for t in hits):
            continue
        score = sum(3 if _is_model(t) else 1 for t in hits)
        if vendor and parts[0] == vendor:
            score += 1
        # Prefer the plain module over its GPU variants
        if parts[-1] in {"nvidia", "intel", "amd"}:
            score -= 0.5
        scored.append((-score, len(name), name))
    return [name for *_, name in sorted(scored)[:limit]]


# ── PCI ───────────────────────────────────────────────────────────────────


@dataclass
class PciDevice:
    address: str  # 0000:3c:00.0
    vendor: str  # 0x10de
    cls: str  # 0x030200
    driver: str  # nvidia, ahci, ... or ""


def pci_devices(sys: Path = SYS) -> list[PciDevice]:
    devices = []
    for dev in sorted((sys / "bus/pci/devices").glob("*")):
        driver = dev / "driver"
        devices.append(
            PciDevice(
                address=dev.name,
                vendor=_read(dev / "vendor"),
                cls=_read(dev / "class"),
                driver=os.path.basename(os.readlink(driver)) if driver.is_symlink() else "",
            )
        )
    return devices


def has_nvidia(devices: list[PciDevice]) -> bool:
    # Optimus dGPUs are often class 0302 (3D controller), not 0300
    return any(d.vendor == "0x10de" and d.cls.startswith("0x03") for d in devices)


def _bus_id(address: str) -> str:
    """0000:3c:00.0 -> PCI:60:0:0 (NixOS wants decimal)."""
    _domain, bus, rest = address.split(":")
    slot, func = rest.split(".")
    return f"PCI:{int(bus, 16)}:{int(slot, 16)}:{int(func, 16)}"


def prime_bus_ids(devices: list[PciDevice]) -> dict[str, str]:
    """hardware.nvidia.prime bus IDs for an iGPU + NVIDIA pair, else nothing."""
    names = {"0x8086": "intelBusId", "0x1002": "amdgpuBusId", "0x10de": "nvidiaBusId"}
    ids: dict[str, str] = {}
    for d in devices:
        if d.cls.startswith("0x03") and d.vendor in names:
            ids.setdefault(names[d.vendor], _bus_id(d.address))
    if "nvidiaBusId" in ids and len(ids) >= 2:
        return ids
    return {}


def kernel_log() -> str:
    for cmd in (["dmesg"], ["journalctl", "-k", "-b", "-q", "--no-pager"]):
        try:
            return util.capture(cmd)
        except (util.CommandFailed, OSError):
            continue
    return ""


def raid_mode(devices: list[PciDevice], klog: str, sys: Path = SYS) -> bool:
    """The firmware hides the NVMe disk behind Intel RST (SATA operation =
    RAID). VMD (also class 0104) and real RAID cards keep their disks visible,
    so only the kernel's own hint or an RST controller on ahci with no NVMe
    disk at all counts."""
    if "remapped NVMe" in klog:
        return True
    rst = any(d.vendor == "0x8086" and d.cls.startswith("0x0104") and d.driver == "ahci" for d in devices)
    return rst and not any((sys / "block").glob("nvme*"))


# ── Disks ─────────────────────────────────────────────────────────────────


@dataclass
class Disk:
    path: str  # /dev/nvme0n1
    size: int
    model: str
    serial: str
    tran: str
    removable: bool
    by_id: str = ""
    installer: bool = False  # holds the booted ISO
    in_use: list[str] = field(default_factory=list)  # mountpoints, [SWAP]
    risky: list[str] = field(default_factory=list)  # "nvme0n1p3: BitLocker"

    @property
    def name(self) -> str:
        return os.path.basename(self.path)

    @property
    def stable_path(self) -> str:
        return self.by_id or self.path

    def label(self) -> str:
        size = f"{self.size / 1024**3:.0f}G"
        bits = [self.name, size, self.model or "?", self.tran or "?"]
        return "  ".join(bits) + (f"  [{self.serial}]" if self.serial else "")


LSBLK_COLS = "NAME,TYPE,SIZE,RM,TRAN,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS"


def lsblk_tree() -> dict:
    return json.loads(util.capture(["lsblk", "-J", "-b", "-p", "-o", LSBLK_COLS]))


def _walk(node: dict):
    yield node
    for child in node.get("children") or []:
        yield from _walk(child)


def by_id_links(dev: Path = Path("/dev/disk/by-id")) -> dict[str, str]:
    """Kernel path -> the most readable stable link (not wwn-/eui, not a partition)."""
    best: dict[str, tuple[tuple[bool, int], str]] = {}
    for link in sorted(dev.glob("*")) if dev.is_dir() else []:
        if "-part" in link.name:
            continue
        target = os.path.realpath(link)
        rank = (link.name.startswith(("wwn-", "nvme-eui.", "nvme-nvme.")), len(link.name))
        if target not in best or rank < best[target][0]:
            best[target] = (rank, str(link))
    return {target: link for target, (_rank, link) in best.items()}


def installer_disks(tree: dict, iso_source: str) -> set[str]:
    """Disks the ISO was booted from: whatever /iso sits on (through dm, as
    with Ventoy), and any disk carrying the NixOS ISO filesystem."""
    found: set[str] = set()
    for disk in tree.get("blockdevices", []):
        for node in _walk(disk):
            if node.get("name") == iso_source:
                found.add(disk["name"])
            if node.get("fstype") == "iso9660" and (node.get("label") or "").startswith("nixos-"):
                found.add(disk["name"])
    if iso_source and not found:
        # /iso on a dm/loop device: follow its slaves down to the disk
        try:
            inverse = json.loads(util.capture(["lsblk", "-J", "-s", "-p", "-o", "NAME,TYPE", iso_source]))
            for top in inverse.get("blockdevices", []):
                found |= {n["name"] for n in _walk(top) if n.get("type") == "disk"}
        except (util.CommandFailed, json.JSONDecodeError):
            pass
    return found


def parse_disks(tree: dict, installer: set[str], by_id: dict[str, str]) -> list[Disk]:
    disks = []
    for d in tree.get("blockdevices", []):
        if d.get("type") != "disk" or d["name"].startswith(("/dev/zram", "/dev/loop", "/dev/sr")):
            continue
        disk = Disk(
            path=d["name"],
            size=int(d.get("size") or 0),
            model=(d.get("model") or "").strip(),
            serial=(d.get("serial") or "").strip(),
            tran=d.get("tran") or "",
            removable=bool(d.get("rm")),
            by_id=by_id.get(d["name"], ""),
            installer=d["name"] in installer,
        )
        for node in _walk(d):
            disk.in_use += [m for m in node.get("mountpoints") or [] if m]
            if node.get("fstype") in RISKY_FSTYPES:
                disk.risky.append(f"{os.path.basename(node['name'])}: {node['fstype']}")
        disks.append(disk)
    return disks


def disks() -> list[Disk]:
    tree = lsblk_tree()
    iso = ""
    try:
        iso = util.capture(["findmnt", "-no", "SOURCE", "/iso"]).strip()
    except util.CommandFailed:
        pass
    return parse_disks(tree, installer_disks(tree, iso), by_id_links())


def candidates(all_disks: list[Disk]) -> list[Disk]:
    return [d for d in all_disks if not d.installer and not d.in_use]


def default_disk(all_disks: list[Disk]) -> Disk | None:
    """The largest fixed disk; never USB or removable (likely another stick)."""
    fixed = [d for d in candidates(all_disks) if not d.removable and d.tran != "usb"]
    return max(fixed, key=lambda d: d.size, default=None)


def resolve(path: str) -> Disk | None:
    real = os.path.realpath(path)
    return next((d for d in disks() if d.path == real), None)


def teardown_commands(tree: dict, disk_path: str) -> list[list[str]]:
    """Release what sits on the disk (LVM on LUKS, md/RST arrays, swap) so
    disko can wipe it, innermost layers first. Only this disk's holders."""
    disk = next((d for d in tree.get("blockdevices", []) if d["name"] == disk_path), None)
    if disk is None:
        return []
    cmds: list[list[str]] = []
    vgs_done: set[str] = set()

    def visit(node: dict) -> None:
        for child in node.get("children") or []:
            visit(child)
        name, kind = node["name"], node.get("type", "")
        if "[SWAP]" in (node.get("mountpoints") or []):
            cmds.append(["swapoff", name])
        if kind == "lvm":
            vg = util.capture(["lvs", "--noheadings", "-o", "vg_name", name], check=False).strip()
            if vg and vg not in vgs_done:
                vgs_done.add(vg)
                cmds.append(["vgchange", "-an", vg])
        elif kind == "crypt":
            cmds.append(["cryptsetup", "close", name])
        elif kind.startswith("raid") or kind == "md":
            cmds.append(["mdadm", "--stop", name])
        if node.get("fstype") in {"linux_raid_member", "isw_raid_member", "ddf_raid_member"}:
            cmds.append(["mdadm", "--zero-superblock", name])

    visit(disk)
    return cmds
