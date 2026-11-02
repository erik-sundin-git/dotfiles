"""The Nix that install-host writes: a new host file, its topology entry, and
in-place edits to a generated host on reinstall.

Every value comes from the installer data or is validated in spec.py, so
nothing here quotes free text. The output is already nixfmt-clean (the tests
check it), and shaped like the hand-written hosts so it can be edited later.
"""

from __future__ import annotations

import re

from .spec import HostSpec, Options

ANCHOR = "# install-host inserts new hosts above this line"


def _list(indent: str, name: str, items: list[str]) -> list[str]:
    if len(items) == 1:
        return [f"{indent}{name} = [ {items[0]} ];"]
    return [f"{indent}{name} = ["] + [f"{indent}  {i}" for i in items] + [f"{indent}];"]


def host_file(spec: HostSpec, opts: Options) -> str:
    assert spec.profile
    sv = opts.state_version
    imports = []
    if spec.hardware:
        imports.append(f"inputs.nixos-hardware.nixosModules.{spec.hardware}")
    imports.append(f"inputs.self.modules.nixos.{spec.profile}")
    if spec.stack:
        imports.append(f"inputs.self.modules.nixos.{spec.stack}")
    imports += [f"inputs.self.modules.nixos.{f}" for f in spec.features]
    imports += ["inputs.self.modules.nixos.diskLayout", "./_hardware.nix"]

    i = " " * 8
    lines = [
        "{ inputs, ... }:",
        "{",
        f"  den.aspects.{spec.host} = {{",
        "    nixos =",
        "      { ... }:",
        "      {",
        *_list(i, "imports", imports),
        "",
        f'{i}systemConstants.system.host = "{spec.host}";',
        f'{i}system.stateVersion = "{sv}";',
        "",
    ]
    if not spec.efi:
        lines.append(f"{i}commonConfig.bootEFI = false;")
    lines += [
        f"{i}diskLayout = {{",
        f'{i}  device = "{spec.disk}";',
        f"{i}  swapGiB = {spec.swap_gib};",
        f"{i}}};",
    ]
    if spec.prime:
        lines.append(f"{i}hardware.nvidia.prime = {{")
        lines += [f'{i}  {k} = "{v}";' for k, v in sorted(spec.prime.items())]
        lines.append(f"{i}}};")

    lines += ["", f"{i}home-manager.users.erik = {{"]
    if spec.home_modules:
        lines += _list(i + "  ", "imports", [f"inputs.self.modules.homeManager.{m}" for m in spec.home_modules])
    if spec.theme and spec.theme != opts.default_theme:
        lines.append(f'{i}  selectedTheme = "{spec.theme}";')
    lines += [
        f'{i}  home.stateVersion = "{sv}";',
        f"{i}}};",
        "      };",
        "  };",
        "}",
    ]
    return "\n".join(lines) + "\n"


def register(topology: str, host: str) -> str:
    """topology.nix with the host added above the anchor (idempotent)."""
    line = f"den.hosts.x86_64-linux.{host} = {{ }};"
    if re.search(rf"^\s*den\.hosts\.x86_64-linux\.{re.escape(host)}\s*=", topology, re.M):
        return topology
    out, n = re.subn(rf"^(\s*){re.escape(ANCHOR)}", rf"\g<1>{line}\n\g<0>", topology, count=1, flags=re.M)
    if n == 0:
        raise ValueError(f"The anchor line is missing from topology.nix: {ANCHOR}")
    return out


def retarget(host_nix: str, disk: str, swap_gib: int) -> str:
    """A generated host file pointed at a new disk (reinstall)."""
    block = re.search(r"diskLayout = \{[^}]*\};", host_nix)
    if not block:
        raise ValueError("No diskLayout block in the host file.")
    new = re.sub(r'device = "[^"]*";', f'device = "{disk}";', block.group(0))
    new = re.sub(r"swapGiB = \d+;", f"swapGiB = {swap_gib};", new)
    return host_nix[: block.start()] + new + host_nix[block.end() :]


# ── Hand-written hardware.nix: swap in the new filesystem UUIDs ──────────────

_UUID_RE = re.compile(r"/dev/disk/by-uuid/([^\"]+)\"")

# (what, line that starts the definition, lines after it to search)
_UUID_SPOTS = {
    "root": (re.compile(r'fileSystems\."/"'), 2),
    "boot": (re.compile(r'fileSystems\."/boot"'), 2),
    "swap": (re.compile(r"swapDevices"), 3),
}


def find_uuid(text: str, what: str) -> str | None:
    start, after = _UUID_SPOTS[what]
    lines = text.splitlines()
    for n, line in enumerate(lines):
        if start.search(line):
            for candidate in lines[n : n + after + 1]:
                if m := _UUID_RE.search(candidate):
                    return m.group(1)
            return None
    return None


def uuid_parts(efi: bool) -> list[str]:
    return ["root", "swap"] + (["boot"] if efi else [])


def missing_uuids(text: str, efi: bool) -> list[str]:
    """Checked before wiping: what patch_uuids couldn't find."""
    return [w for w in uuid_parts(efi) if not find_uuid(text, w)]


def patch_uuids(text: str, new: dict[str, str]) -> str:
    for what, uuid in new.items():
        old = find_uuid(text, what)
        if not old:
            raise ValueError(f"No {what} UUID in hardware.nix")
        text = text.replace(old, uuid)
    return text
