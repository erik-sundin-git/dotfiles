import pytest

from install_host.spec import HostSpec, Options, SchemaMismatch, hostname_error, validate

from .conftest import INSTALLER

HOSTS = ["nomad", "forge"]
DIRS = ["nomad", "forge", "common", "live-iso"]


def laptop(**kw):
    base = dict(
        host="xps",
        profile="laptopBaseProfile",
        stack="swayfxStack",
        disk="/dev/disk/by-id/nvme-Samsung_SSD_970_S1",
        disk_size=512 * 1024**3,
        swap_gib=16,
    )
    return HostSpec(**{**base, **kw})


@pytest.mark.parametrize("name", ["xps", "a", "web-1", "x" * 63])
def test_hostname_ok(name):
    assert hostname_error(name, HOSTS, DIRS) is None


@pytest.mark.parametrize(
    "name", ["", "Xps", "1xps", "xps-", "x" * 64, "in", "let", "nomad", "common", "live-iso", "a_b"]
)
def test_hostname_rejected(name):
    assert hostname_error(name, HOSTS, DIRS)


def test_valid_laptop(opts):
    assert validate(laptop(features=["gaming"], home_modules=["gh"]), opts, HOSTS, DIRS) == []


def test_nvidia_blocked_on_wayland(opts):
    errors = validate(laptop(hardware="dell-xps-15-7590-nvidia"), opts, HOSTS, DIRS)
    assert any("NVIDIA" in e for e in errors)


def test_nvidia_allowed_on_x11(opts):
    spec = laptop(
        stack="i3Stack",
        hardware="dell-xps-15-7590-nvidia",
        prime={"nvidiaBusId": "PCI:1:0:0", "intelBusId": "PCI:0:2:0"},
    )
    assert validate(spec, opts, HOSTS, DIRS) == []


def test_stack_rules(opts):
    assert validate(laptop(stack=None), opts, HOSTS, DIRS)
    assert validate(laptop(profile="vmProfile"), opts, HOSTS, DIRS)  # vm brings xfce
    assert validate(laptop(profile="vmProfile", stack=None), opts, HOSTS, DIRS) == []


def test_extras_follow_profile(opts):
    server = dict(profile="serverProfile", stack=None)
    assert validate(laptop(**server), opts, HOSTS, DIRS) == []
    assert validate(laptop(**server, features=["gaming"]), opts, HOSTS, DIRS)
    assert validate(laptop(**server, home_modules=["chromium"]), opts, HOSTS, DIRS)
    assert validate(laptop(**server, home_modules=["gh"]), opts, HOSTS, DIRS) == []


def test_disk_and_swap(opts):
    assert validate(laptop(disk="/dev/sda; rm -rf /"), opts, HOSTS, DIRS)
    assert validate(laptop(swap_gib=0), opts, HOSTS, DIRS)
    assert validate(laptop(disk_size=30 * 1024**3, swap_gib=16), opts, HOSTS, DIRS)
    assert validate(laptop(disk_size=40 * 1024**3, swap_gib=16), opts, HOSTS, DIRS) == []


def test_reinstall(opts):
    ok = HostSpec(host="nomad", new=False, disk="/dev/sda", disk_size=10**12)
    assert validate(ok, opts, HOSTS, DIRS) == []
    ghost = HostSpec(host="ghost", new=False, disk="/dev/sda", disk_size=10**12)
    assert validate(ghost, opts, HOSTS, DIRS)


def test_json_roundtrip():
    spec = laptop(features=["gaming"], prime={"intelBusId": "PCI:0:2:0"})
    assert HostSpec.from_json(spec.to_json()) == spec
    with pytest.raises(ValueError):
        HostSpec.from_json('{"host": "x", "bogus": 1}')


def test_schema_mismatch():
    with pytest.raises(SchemaMismatch):
        Options({**INSTALLER, "schemaVersion": 99})


def test_options_order(opts):
    assert [n for n, _ in opts.stacks] == ["swayfxStack", "i3Stack", "hyprlandStack"]
    assert opts.default_stack == "swayfxStack"
    assert opts.profile_for_type("laptop") == "laptopBaseProfile"
