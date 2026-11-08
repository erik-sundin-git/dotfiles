"""What gets installed: the installer data from the flake, and the answers
(from the wizard or --answers) checked against it."""

from __future__ import annotations

import dataclasses
import hashlib
import json
import re
from dataclasses import dataclass, field

# Bumped together with flake.installer.schemaVersion (installer-options.nix)
SCHEMA_VERSION = 1

GIB = 1024**3
MIN_ROOT_GIB = 20
ESP_GIB = 0.5

HOSTNAME_RE = re.compile(r"^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$")
# The host name is written unquoted into topology.nix and den.aspects
NIX_KEYWORDS = {"assert", "else", "if", "in", "inherit", "let", "or", "rec", "then", "with"}
DISK_RE = re.compile(r"^/dev/[A-Za-z0-9._:/+-]+$")
BUS_ID_RE = re.compile(r"^PCI:\d+:\d+:\d+$")


class SchemaMismatch(Exception):
    pass


class Options:
    """flake.installer, as `nix eval --json .#installer` returns it."""

    def __init__(self, data: dict):
        if data.get("schemaVersion") != SCHEMA_VERSION:
            raise SchemaMismatch(
                f"The flake's installer data is schema {data.get('schemaVersion')}, this "
                f"install-host reads schema {SCHEMA_VERSION}. Rebuild the ISO, or run "
                "`nix run /tmp/dotfiles#install-host`."
            )
        self.data = data

    def _sorted(self, kind: str) -> list[tuple[str, dict]]:
        return sorted(self.data[kind].items(), key=lambda kv: (kv[1]["order"], kv[0]))

    @property
    def profiles(self) -> list[tuple[str, dict]]:
        return self._sorted("profiles")

    @property
    def stacks(self) -> list[tuple[str, dict]]:
        return self._sorted("stacks")

    def features(self, profile: str) -> list[tuple[str, dict]]:
        return [(n, e) for n, e in self._sorted("features") if profile in e["profiles"]]

    def home_modules(self, profile: str) -> list[tuple[str, dict]]:
        return [(n, e) for n, e in self._sorted("homeModules") if profile in e["profiles"]]

    def profile(self, name: str) -> dict:
        return self.data["profiles"][name]

    def stack(self, name: str) -> dict:
        return self.data["stacks"][name]

    @property
    def default_stack(self) -> str:
        return next(n for n, e in self.stacks if e["default"])

    def profile_for_type(self, type_: str) -> str:
        return next(n for n, e in self.profiles if e["type"] == type_)

    @property
    def themes(self) -> list[str]:
        return sorted(self.data["themes"])

    @property
    def default_theme(self) -> str:
        return self.data["defaultTheme"]

    @property
    def state_version(self) -> str:
        return self.data["stateVersion"]

    @property
    def hardware(self) -> list[str]:
        return self.data["nixosHardware"]


@dataclass
class HostSpec:
    host: str = ""
    new: bool = True  # False: reinstall a host already in topology.nix
    profile: str | None = None
    stack: str | None = None
    features: list[str] = field(default_factory=list)
    home_modules: list[str] = field(default_factory=list)
    theme: str | None = None
    hardware: str | None = None
    # hardware.nvidia.prime bus IDs, e.g. {"intelBusId": "PCI:0:2:0"}
    prime: dict[str, str] = field(default_factory=dict)
    disk: str = ""  # a /dev/disk/by-id path, or the kernel name when there's none
    disk_serial: str = ""
    disk_size: int = 0  # bytes
    swap_gib: int = 16
    efi: bool = True

    def to_json(self) -> str:
        return json.dumps(dataclasses.asdict(self), indent=2, sort_keys=True)

    @classmethod
    def from_json(cls, text: str) -> HostSpec:
        data = json.loads(text)
        known = {f.name for f in dataclasses.fields(cls)}
        unknown = set(data) - known
        if unknown:
            raise ValueError(f"Unknown answers keys: {', '.join(sorted(unknown))}")
        return cls(**data)

    def digest(self) -> str:
        return hashlib.sha256(self.to_json().encode()).hexdigest()


def is_nvidia_module(name: str | None) -> bool:
    return bool(name) and name.endswith("-nvidia")  # type: ignore[union-attr]


def wayland_conflict(opts: Options, stack: str | None, hardware: str | None) -> bool:
    """sway on the proprietary driver; the stack asserts against it too."""
    return bool(stack) and opts.stack(stack)["session"] == "wayland" and is_nvidia_module(hardware)


def hostname_error(name: str, existing_hosts: list[str], host_dirs: list[str]) -> str | None:
    if not HOSTNAME_RE.match(name):
        return "Use lowercase letters, digits and dashes (start with a letter, max 63)."
    if name in NIX_KEYWORDS:
        return f"'{name}' is a Nix keyword."
    if name in existing_hosts:
        return f"'{name}' is already a host; pick it under Reinstall instead."
    if name in host_dirs:
        return f"nix/modules/hosts/{name} already exists."
    return None


def swap_error(swap_gib: int, disk_size: int) -> str | None:
    if swap_gib < 1:
        return "Swap must be at least 1 GiB."
    if disk_size and disk_size < (ESP_GIB + swap_gib + MIN_ROOT_GIB) * GIB:
        return f"The disk is too small for {swap_gib} GiB swap plus a {MIN_ROOT_GIB} GiB root."
    return None


def validate(
    spec: HostSpec,
    opts: Options,
    existing_hosts: list[str],
    host_dirs: list[str],
    *,
    need_disk: bool = True,
) -> list[str]:
    """Everything wrong with the answers; empty when they can be installed.
    Shared by the wizard and --answers, so both refuse the same things."""
    errors: list[str] = []

    if spec.new:
        if err := hostname_error(spec.host, existing_hosts, host_dirs):
            errors.append(err)
        if spec.profile not in opts.data["profiles"]:
            errors.append(f"Unknown profile: {spec.profile}")
            return errors
        if opts.profile(spec.profile)["stacks"]:
            if spec.stack not in opts.data["stacks"]:
                errors.append("Pick a window manager stack.")
        elif spec.stack:
            errors.append(f"{spec.profile} brings its own desktop; it takes no stack.")
        allowed = {n for n, _ in opts.features(spec.profile)}
        errors += [f"Feature {f} isn't offered for {spec.profile}." for f in spec.features if f not in allowed]
        allowed = {n for n, _ in opts.home_modules(spec.profile)}
        errors += [f"Home module {m} isn't offered for {spec.profile}." for m in spec.home_modules if m not in allowed]
        if spec.theme is not None and spec.theme not in opts.themes:
            errors.append(f"Unknown theme: {spec.theme}")
        if spec.hardware is not None and spec.hardware not in opts.hardware:
            errors.append(f"Unknown nixos-hardware module: {spec.hardware}")
        if wayland_conflict(opts, spec.stack, spec.hardware):
            errors.append(
                f"{spec.hardware} uses the proprietary NVIDIA driver, which "
                f"{opts.stack(spec.stack)['label']} can't run on. Pick an X11 stack or a "  # type: ignore[index]
                "module without -nvidia."
            )
        errors += [f"Bad PCI bus ID: {v}" for v in spec.prime.values() if not BUS_ID_RE.match(v)]
    elif spec.host not in existing_hosts:
        errors.append(f"{spec.host} isn't in topology.nix.")

    if need_disk:
        if not DISK_RE.match(spec.disk):
            errors.append(f"Bad disk path: {spec.disk!r}")
        if err := swap_error(spec.swap_gib, spec.disk_size):
            errors.append(err)
    return errors
