import shutil
import subprocess

import pytest

from install_host import nixgen
from install_host.spec import HostSpec

TOPOLOGY = """{ ... }:
{
  den.hosts.x86_64-linux.nomad = { };
  # install-host inserts new hosts above this line
}
"""

HARDWARE_NIX = """{
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/f346b9b7-root";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2538-F177";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/63cfc2dc-swap"; }
    ];
}
"""


def spec(**kw):
    base = dict(
        host="xps",
        profile="laptopBaseProfile",
        stack="swayfxStack",
        disk="/dev/disk/by-id/nvme-Samsung_SSD_970_S1",
        disk_size=512 * 1024**3,
        swap_gib=16,
        theme="onedark",
    )
    return HostSpec(**{**base, **kw})


VARIANTS = {
    "minimal": spec(),
    "full": spec(
        hardware="dell-xps-15-7590-nvidia",
        stack="i3Stack",
        features=["gaming", "virtManager"],
        home_modules=["gh", "chromium"],
        theme="ef-bio",
        prime={"intelBusId": "PCI:0:2:0", "nvidiaBusId": "PCI:1:0:0"},
    ),
    "one-hm-module": spec(home_modules=["gh"]),
    "server": spec(profile="serverProfile", stack=None, theme=None),
    "bios-vm": spec(profile="vmProfile", stack=None, efi=False, disk="/dev/vda"),
}


@pytest.mark.parametrize("name", VARIANTS)
def test_host_file_is_nixfmt_clean(opts, name, tmp_path):
    if not shutil.which("nixfmt"):
        pytest.skip("nixfmt not on PATH")
    path = tmp_path / "host.nix"
    path.write_text(nixgen.host_file(VARIANTS[name], opts))
    result = subprocess.run(["nixfmt", "--check", str(path)], capture_output=True, text=True)
    assert result.returncode == 0, path.read_text() + result.stderr


def test_host_file_contents(opts):
    text = nixgen.host_file(VARIANTS["full"], opts)
    assert "den.aspects.xps = {" in text
    assert "inputs.nixos-hardware.nixosModules.dell-xps-15-7590-nvidia" in text
    assert "inputs.self.modules.nixos.i3Stack" in text
    assert "inputs.self.modules.nixos.gaming" in text
    assert "inputs.self.modules.nixos.diskLayout" in text
    assert "./_hardware.nix" in text
    assert 'nvidiaBusId = "PCI:1:0:0";' in text
    assert 'selectedTheme = "ef-bio";' in text
    assert 'system.stateVersion = "26.05";' in text
    assert 'home.stateVersion = "26.05";' in text
    assert "with " not in text


def test_defaults_left_out(opts):
    text = nixgen.host_file(VARIANTS["minimal"], opts)
    assert "selectedTheme" not in text  # onedark is the default
    assert "bootEFI" not in text
    assert "prime" not in text
    assert "homeManager" not in text


def test_bios(opts):
    text = nixgen.host_file(VARIANTS["bios-vm"], opts)
    assert "commonConfig.bootEFI = false;" in text
    assert "inputs.self.modules.nixos.vmProfile" in text


def test_register():
    out = nixgen.register(TOPOLOGY, "xps")
    assert "  den.hosts.x86_64-linux.xps = { };\n  # install-host inserts" in out
    assert nixgen.register(out, "xps") == out  # idempotent
    with pytest.raises(ValueError):
        nixgen.register("{ }\n", "xps")


def test_retarget(opts):
    text = nixgen.host_file(spec(), opts)
    out = nixgen.retarget(text, "/dev/disk/by-id/ata-NEW", 32)
    assert 'device = "/dev/disk/by-id/ata-NEW";' in out
    assert "swapGiB = 32;" in out
    assert out.count("diskLayout") == text.count("diskLayout")


def test_uuids():
    assert nixgen.missing_uuids(HARDWARE_NIX, efi=True) == []
    assert nixgen.missing_uuids("{ }", efi=False) == ["root", "swap"]
    new = {"root": "NEW-ROOT", "swap": "NEW-SWAP", "boot": "NEW-BOOT"}
    out = nixgen.patch_uuids(HARDWARE_NIX, new)
    assert all(f"by-uuid/{u}" in out for u in new.values())
    assert "f346b9b7" not in out
