import json

from install_host import system
from install_host.system import PciDevice

from .conftest import INSTALLER

HW = INSTALLER["nixosHardware"]

XPS = {"sys_vendor": "Dell Inc.", "product_name": "XPS 15 7590", "product_version": "", "chassis_type": "10"}
T480S = {"sys_vendor": "LENOVO", "product_name": "20L7CTO1WW", "product_version": "ThinkPad T480s", "chassis_type": "10"}
DESKTOP = {"sys_vendor": "ASUS", "product_name": "System Product Name", "product_version": "", "chassis_type": "3"}


def test_suggestions():
    assert system.suggest_hardware(XPS, HW)[:2] == ["dell-xps-15-7590", "dell-xps-15-7590-nvidia"]
    assert system.suggest_hardware(T480S, HW)[0] == "lenovo-thinkpad-t480s"
    assert "lenovo-thinkpad-t480" not in system.suggest_hardware(T480S, HW)
    assert system.suggest_hardware(DESKTOP, HW) == []


def test_default_type():
    assert system.default_type(XPS, vm=False) == "laptop"
    assert system.default_type(DESKTOP, vm=False) == "desktop"
    assert system.default_type(XPS, vm=True) == "vm"
    assert system.default_type({"chassis_type": ""}, vm=False) == "desktop"


def test_ram():
    assert system.ram_gib("MemTotal:       15950000 kB\n") == 16
    assert system.ram_gib("MemTotal:       8000000 kB\n") == 8


XPS_PCI = [
    PciDevice("0000:00:02.0", "0x8086", "0x030000", "i915"),
    PciDevice("0000:00:17.0", "0x8086", "0x010400", "ahci"),  # RST in RAID mode
    PciDevice("0000:3c:00.0", "0x10de", "0x030200", ""),  # Optimus: 3D controller
]


def test_nvidia_and_prime():
    assert system.has_nvidia(XPS_PCI)
    assert system.prime_bus_ids(XPS_PCI) == {"intelBusId": "PCI:0:2:0", "nvidiaBusId": "PCI:60:0:0"}
    assert system.prime_bus_ids(XPS_PCI[:2]) == {}


def test_raid_mode(tmp_path):
    (tmp_path / "block").mkdir()
    assert system.raid_mode(XPS_PCI, "", tmp_path)
    assert system.raid_mode([], "ahci 0000:00:17.0: Found 1 remapped NVMe devices.", tmp_path)
    vmd = [PciDevice("0000:00:0e.0", "0x8086", "0x010400", "vmd")]
    assert not system.raid_mode(vmd, "", tmp_path)
    (tmp_path / "block/nvme0n1").mkdir()
    assert not system.raid_mode(XPS_PCI, "", tmp_path)


LSBLK = json.loads("""{"blockdevices": [
  {"name": "/dev/sda", "type": "disk", "size": 61872793600, "rm": true, "tran": "usb", "model": "DataTraveler 3.0", "serial": "KS1", "fstype": "iso9660", "label": "nixos-26.05-x86_64", "mountpoints": [null],
   "children": [{"name": "/dev/sda1", "type": "part", "size": 6000000000, "fstype": "iso9660", "label": "nixos-26.05-x86_64", "mountpoints": ["/iso"]}]},
  {"name": "/dev/nvme0n1", "type": "disk", "size": 512110190592, "rm": false, "tran": "nvme", "model": "PM981", "serial": "S1", "fstype": null, "label": null, "mountpoints": [null],
   "children": [{"name": "/dev/nvme0n1p3", "type": "part", "size": 400000000000, "fstype": "BitLocker", "label": null, "mountpoints": [null]}]},
  {"name": "/dev/sdb", "type": "disk", "size": 1000204886016, "rm": false, "tran": "sata", "model": "HDD", "serial": "H1", "fstype": null, "label": null, "mountpoints": [null],
   "children": [{"name": "/dev/sdb1", "type": "part", "size": 1000204886016, "fstype": "ext4", "label": null, "mountpoints": ["/data"]}]},
  {"name": "/dev/sdc", "type": "disk", "size": 2000398934016, "rm": false, "tran": "usb", "model": "Ext", "serial": "U1", "fstype": null, "label": null, "mountpoints": [null]},
  {"name": "/dev/zram0", "type": "disk", "size": 8000000000, "rm": false, "tran": null, "model": null, "serial": null, "fstype": "swap", "label": null, "mountpoints": ["[SWAP]"]}
]}""")


def test_disks():
    installer = system.installer_disks(LSBLK, "/dev/sda1")
    assert installer == {"/dev/sda"}
    disks = system.parse_disks(LSBLK, installer, {"/dev/nvme0n1": "/dev/disk/by-id/nvme-PM981_S1"})
    by_name = {d.name: d for d in disks}
    assert "zram0" not in by_name
    assert by_name["sda"].installer
    assert by_name["sdb"].in_use == ["/data"]
    assert by_name["nvme0n1"].risky == ["nvme0n1p3: BitLocker"]
    assert by_name["nvme0n1"].stable_path == "/dev/disk/by-id/nvme-PM981_S1"
    # Not the ISO, not mounted, and the bigger USB disk is never the default
    assert [d.name for d in system.candidates(disks)] == ["nvme0n1", "sdc"]
    assert system.default_disk(disks).name == "nvme0n1"


def test_teardown_order():
    tree = {"blockdevices": [{
        "name": "/dev/sdd", "type": "disk", "fstype": "isw_raid_member", "mountpoints": [None],
        "children": [
            {"name": "/dev/md126", "type": "raid1", "fstype": None, "mountpoints": [None]},
            {"name": "/dev/sdd2", "type": "part", "fstype": "crypto_LUKS", "mountpoints": [None],
             "children": [{"name": "/dev/mapper/luks", "type": "crypt", "fstype": "swap", "mountpoints": ["[SWAP]"]}]},
        ],
    }]}
    assert system.teardown_commands(tree, "/dev/sdd") == [
        ["mdadm", "--stop", "/dev/md126"],
        ["swapoff", "/dev/mapper/luks"],
        ["cryptsetup", "close", "/dev/mapper/luks"],
        ["mdadm", "--zero-superblock", "/dev/sdd"],
    ]
    assert system.teardown_commands(tree, "/dev/other") == []
