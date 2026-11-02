"""The wizard: mode -> (new host form) -> disk -> review/evaluate -> confirm.

Nothing here touches a disk. It ends with an evaluated HostSpec and the
clone's Changes; main.py does the rest outside the TUI.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

from . import nixgen, system, ui, util
from .install import unmount
from .repo import Changes, Repo, find_keys
from .spec import (
    HostSpec,
    Options,
    hostname_error,
    is_nvidia_module,
    swap_error,
    validate,
    wayland_conflict,
)


@dataclass
class Context:
    repo: Repo
    opts: Options
    efi: bool
    dmi: dict[str, str]
    vm: bool
    pci: list[system.PciDevice]
    raid: bool
    ram_gib: int
    hardware_suggestions: list[str] = field(default_factory=list)

    @classmethod
    def detect(cls, repo: Repo, opts: Options) -> Context:
        info = system.dmi()
        pci = system.pci_devices()
        return cls(
            repo=repo,
            opts=opts,
            efi=system.firmware_efi(),
            dmi=info,
            vm=system.is_vm(),
            pci=pci,
            raid=system.raid_mode(pci, system.kernel_log()),
            ram_gib=system.ram_gib(),
            hardware_suggestions=system.suggest_hardware(info, opts.hardware),
        )

    @property
    def machine(self) -> str:
        d = self.dmi
        return " ".join(x for x in (d["sys_vendor"], d["product_name"], d["product_version"]) if x) or "unknown machine"


RAID_HINT = (
    "The firmware's SATA operation is set to RAID (Intel RST), which hides NVMe "
    "disks from Linux. Set it to AHCI in the firmware setup (Dell: F2, System "
    "Configuration > SATA Operation), then boot the installer again. A Windows "
    "install on the disk needs preparing before that switch."
)
# The detection missed it, but an empty list is the usual symptom
RAID_MAYBE = (
    "If an NVMe disk is missing, check whether the firmware's SATA operation is "
    "set to RAID (Intel RST) and switch it to AHCI (Dell: F2, System "
    "Configuration > SATA Operation)."
)


# ── New host ──────────────────────────────────────────────────────────────


def _defaults(ctx: Context, spec: HostSpec) -> None:
    opts = ctx.opts
    type_ = system.default_type(ctx.dmi, ctx.vm)
    spec.profile = "vmProfile" if type_ == "vm" else opts.profile_for_type(type_)
    _set_profile(ctx, spec, spec.profile)
    spec.theme = opts.default_theme


def _set_profile(ctx: Context, spec: HostSpec, profile: str) -> None:
    opts = ctx.opts
    spec.profile = profile
    p = opts.profile(profile)
    spec.stack = opts.default_stack if p["stacks"] else None
    spec.features = [f for f in spec.features if f in dict(opts.features(profile))]
    spec.home_modules = [m for m in spec.home_modules if m in dict(opts.home_modules(profile))]
    if profile == "vmProfile":
        spec.hardware = None
    elif spec.hardware is None:
        spec.hardware = next(
            (h for h in ctx.hardware_suggestions if not wayland_conflict(opts, spec.stack, h)), None
        )
    if p["type"] == "server":
        spec.theme = None
    elif spec.theme is None:
        spec.theme = opts.default_theme
    _update_prime(ctx, spec)


def _update_prime(ctx: Context, spec: HostSpec) -> None:
    spec.prime = system.prime_bus_ids(ctx.pci) if is_nvidia_module(spec.hardware) else {}


def _pick_hostname(ctx: Context, spec: HostSpec) -> None:
    hosts, dirs = ctx.repo.hosts(), ctx.repo.host_dirs()
    value = ui.text_input(
        "Hostname",
        "The host's name: the flake attribute, nix/modules/hosts/<name>, and networking.hostName.",
        "Hostname: ",
        spec.host,
        lambda v: hostname_error(v, hosts, dirs),
    )
    if value is not ui.BACK:
        spec.host = value


def _pick_profile(ctx: Context, spec: HostSpec) -> None:
    items = [(e["label"], name) for name, e in ctx.opts.profiles]
    value = ui.menu("Type", f"Detected: {ctx.machine}{' (virtual machine)' if ctx.vm else ''}", items)
    if value is not ui.BACK:
        _set_profile(ctx, spec, value)


def _pick_stack(ctx: Context, spec: HostSpec) -> None:
    items: list = []
    for name, e in ctx.opts.stacks:
        label = e["label"] + (" (untested)" if e["experimental"] else "")
        if wayland_conflict(ctx.opts, name, spec.hardware):
            items.append((label, name, f"not with {spec.hardware}"))
        else:
            items.append((label, name))
    value = ui.menu("Window manager", "One stack per host.", items)
    if value is not ui.BACK:
        spec.stack = value


def _pick_hardware(ctx: Context, spec: HostSpec) -> None:
    def item(name: str) -> tuple:
        if wayland_conflict(ctx.opts, spec.stack, name):
            return (name, name, "proprietary NVIDIA driver; needs an X11 stack")
        return (name, name)

    intro = [f"Detected: {ctx.machine}\n"]
    if system.has_nvidia(ctx.pci):
        intro.append(
            ("warn", "This machine has an NVIDIA GPU. ")
            if spec.stack and ctx.opts.stack(spec.stack)["session"] == "wayland"
            else ""
        )
        intro.append(
            "-nvidia modules use the proprietary driver (X11 stacks only); the plain or -intel "
            "module runs on the integrated GPU.\n"
        )
    value = ui.filter_menu(
        "Hardware module (nixos-hardware)",
        intro,
        [item(n) for n in ctx.hardware_suggestions],
        [item(n) for n in ctx.opts.hardware],
        extra=[("None (generic hardware)", "")],
    )
    if value is not ui.BACK:
        spec.hardware = value or None
        _update_prime(ctx, spec)


def _pick_theme(ctx: Context, spec: HostSpec) -> None:
    items = [(t + (" (default)" if t == ctx.opts.default_theme else ""), t) for t in ctx.opts.themes]
    value = ui.menu("Theme", None, items)
    if value is not ui.BACK:
        spec.theme = value


def _pick_extras(ctx: Context, spec: HostSpec) -> None:
    assert spec.profile
    items = [(f"{e['label']}", ("f", n), n in spec.features) for n, e in ctx.opts.features(spec.profile)]
    items += [
        (f"{e['label']} (home)", ("h", n), n in spec.home_modules) for n, e in ctx.opts.home_modules(spec.profile)
    ]
    if not items:
        ui.message("Extras", "Nothing extra is offered for this type.")
        return
    value = ui.checklist("Extras", "NixOS features, and Home Manager modules for erik.", items)
    if value is not ui.BACK:
        spec.features = [n for kind, n in value if kind == "f"]
        spec.home_modules = [n for kind, n in value if kind == "h"]


def new_host_form(ctx: Context, spec: HostSpec) -> object:
    """One screen with every choice pre-filled; Enter on a row changes it."""
    opts = ctx.opts
    if spec.profile is None:
        _defaults(ctx, spec)
    while True:
        assert spec.profile
        p = opts.profile(spec.profile)
        extras = [opts.data["features"][f]["label"] for f in spec.features]
        extras += [opts.data["homeModules"][m]["label"] for m in spec.home_modules]
        rows: list = [
            (f"Hostname:  {spec.host or '(not set)'}", _pick_hostname),
            (f"Type:      {p['label']}", _pick_profile),
        ]
        if p["stacks"]:
            stack = opts.stack(spec.stack)["label"] if spec.stack else "(not set)"
            rows.append((f"Desktop:   {stack}", _pick_stack))
        if spec.profile != "vmProfile":
            rows.append((f"Hardware:  {spec.hardware or 'none (generic)'}", _pick_hardware))
        if p["type"] != "server":
            rows.append((f"Theme:     {spec.theme}", _pick_theme))
        rows.append((f"Extras:    {', '.join(extras) or 'none'}", _pick_extras))
        rows.append(("Continue >", "next"))
        choice = ui.menu("New host", f"Detected: {ctx.machine}", rows)
        if choice is ui.BACK:
            return ui.BACK
        if choice == "next":
            errors = validate(spec, opts, ctx.repo.hosts(), ctx.repo.host_dirs(), need_disk=False)
            if not errors:
                return None
            ui.message("Not yet", "\n".join(errors))
        else:
            choice(ctx, spec)


# ── Disk ──────────────────────────────────────────────────────────────────


def pick_disk(ctx: Context, spec: HostSpec) -> object:
    disks = system.disks()
    default = None if ctx.raid else system.default_disk(disks)
    intro: list = []
    if ctx.raid:
        intro.append(("error", RAID_HINT + "\n\n"))
    intro.append("Everything on the disk you pick is erased (after one more confirmation).")
    items: list = []
    ordered = sorted(disks, key=lambda d: d is not default)
    for d in ordered:
        label = d.label() + ("  (suggested)" if d is default else "")
        if d.installer:
            items.append((label, d, "the installer medium"))
        elif d.in_use:
            items.append((label, d, "in use: " + ", ".join(d.in_use)))
        else:
            if d.tran == "usb" or d.removable:
                label += "  (USB/removable)"
            if d.risky:
                label += "  [" + "; ".join(d.risky) + "]"
            items.append((label, d))
    if not system.candidates(disks):
        intro.append(("warn", "\n\nNo disk to install to." + ("" if ctx.raid else " " + RAID_MAYBE)))
    disk = ui.menu("Disk", intro, items)
    if disk is ui.BACK:
        return ui.BACK

    swap = ui.text_input(
        "Swap",
        f"Swap partition size. Hibernate needs at least the RAM size ({ctx.ram_gib} GiB).",
        "Swap (GiB): ",
        str(spec.swap_gib if spec.disk else ctx.ram_gib),
        lambda v: "A whole number of GiB." if not v.isdigit() else swap_error(int(v), disk.size),
    )
    if swap is ui.BACK:
        return pick_disk(ctx, spec)
    spec.disk, spec.disk_serial, spec.disk_size = disk.stable_path, disk.serial, disk.size
    spec.swap_gib = int(swap)
    spec.efi = ctx.efi
    return None


# ── Review: write the host into the clone and evaluate it ────────────────


def hardware_config() -> str:
    """Kernel modules, CPU microcode, firmware; filesystems come from disko."""
    return util.capture(["nixos-generate-config", "--show-hardware-config", "--no-filesystems"])


def _stage(ctx: Context, spec: HostSpec, changes: Changes) -> str:
    """Write what the install will use; returns a summary."""
    repo = ctx.repo
    host_dir = repo.host_dir(spec.host)
    if spec.new:
        text = nixgen.host_file(spec, ctx.opts)
        changes.write(host_dir / f"{spec.host}.nix", text)
        changes.write(host_dir / "_hardware.nix", hardware_config())
        changes.write(repo.topology, nixgen.register(repo.topology.read_text(), spec.host))
        return text
    if repo.host_uses_disko(spec.host):
        host_nix = host_dir / f"{spec.host}.nix"
        changes.write(host_nix, nixgen.retarget(host_nix.read_text(), spec.disk, spec.swap_gib))
        changes.write(host_dir / "_hardware.nix", hardware_config())
        return f"Reinstall {spec.host} (disko layout, retargeted to {spec.disk})."
    return (
        f"Reinstall {spec.host}: its hand-written hardware.nix keeps everything but the "
        "filesystem UUIDs, which are patched after partitioning."
    )


def _reinstall_checks(ctx: Context, spec: HostSpec) -> list[str]:
    repo = ctx.repo
    problems = []
    host_efi = repo.host_efi(spec.host)
    if host_efi != ctx.efi:
        mode = lambda efi: "UEFI" if efi else "BIOS"  # noqa: E731
        problems.append(
            f"{spec.host} is configured for {mode(host_efi)} boot, but the installer was booted in "
            f"{mode(ctx.efi)} mode. Boot it in {mode(host_efi)} mode."
        )
    if not repo.host_uses_disko(spec.host):
        hw = repo.host_dir(spec.host) / "hardware.nix"
        if not hw.is_file():
            problems.append(f"{spec.host} has neither diskLayout nor a hardware.nix to patch.")
        elif missing := nixgen.missing_uuids(hw.read_text(), ctx.efi):
            problems.append(
                f"Can't find the {', '.join(missing)} UUID(s) in {hw}; edit it by hand and run "
                "nixos-install yourself."
            )
    return problems


def review(ctx: Context, spec: HostSpec, changes: Changes) -> object:
    """Write, evaluate, show. On any failure (or Back) the clone is rolled back."""
    repo = ctx.repo
    if spec.efi != ctx.efi:
        if spec.new:
            spec.efi = ctx.efi
        else:
            # Resumed answers from a run booted the other way
            ui.message("Firmware mode changed", "The installer was booted in a different mode than these answers. Pick the disk again.")
            return ui.BACK
    try:
        if not spec.new:
            problems = ui.spinner("Checking", f"Evaluating {spec.host}", lambda: _reinstall_checks(ctx, spec))
            if problems:
                ui.message("Can't reinstall", "\n\n".join(problems))
                return ui.BACK
        summary = _stage(ctx, spec, changes)
        ui.spinner("Evaluating", f"nix eval {spec.host} (fetches inputs on a fresh ISO)", lambda: repo.eval_host(spec.host))
    except util.CommandFailed as e:
        changes.rollback()
        ui.message("Evaluation failed", (e.output or str(e)).strip() + "\n\nNothing was changed.")
        return ui.BACK

    notes = []
    if not spec.new and repo.is_sops_recipient(spec.host):
        notes.append(
            f"{spec.host} is a sops recipient: the reinstall gets a new SSH host key, so update its age "
            "key in nix/secrets/.sops.yaml and run `sops updatekeys secrets.yaml` afterwards."
        )
    layout = "ESP 512M + " if spec.efi else "bios_grub 1M + "
    text = (
        f"{summary}\n\nDisk: {spec.disk}\nLayout: GPT, {layout}swap {spec.swap_gib}G + ext4 root\n"
        + ("\n" + "\n".join(notes) + "\n" if notes else "")
    )
    choice = ui.message("Review", text, [("Continue >", "next"), ("< Back", ui.BACK)])
    if choice is ui.BACK:
        changes.rollback()
        return ui.BACK
    util.ANSWERS_FILE.write_text(spec.to_json())
    return None


def confirm_erase(spec: HostSpec) -> object:
    disk = system.resolve(spec.disk)
    if disk is None:
        ui.message("Disk gone", f"{spec.disk} disappeared.")
        return ui.BACK
    lsblk = util.capture(["lsblk", "-o", "NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS", disk.path], check=False)
    warning: list = []
    if disk.risky:
        warning = [("error", "It holds: " + ", ".join(disk.risky) + "\n\n")]
    intro = [
        ("bold", f"Erase {disk.label()}?\n\n"),
        lsblk + "\n",
        *warning,
        f"Type {disk.name} to erase it and install {spec.host}.",
    ]
    value = ui.text_input(
        "Erase disk",
        intro,
        "Disk name: ",
        "",
        lambda v: None if v == disk.name else f"Type exactly: {disk.name}",
    )
    return ui.BACK if value is ui.BACK else None


# ── The whole wizard ──────────────────────────────────────────────────────


def choose_mode(ctx: Context, spec: HostSpec) -> object:
    hosts = ctx.repo.hosts()
    items = [(f"Reinstall {h}", h) for h in hosts] + [("New host...", ""), ("Quit", None)]
    value = ui.menu("Install", f"Detected: {ctx.machine}  ({'UEFI' if ctx.efi else 'BIOS'} boot)", items, back=False)
    if value is None:
        return ui.BACK
    if value:
        _reset(spec, HostSpec(host=value, new=False))
    elif not spec.new:
        _reset(spec, HostSpec())
    return None


def _reset(spec: HostSpec, fresh: HostSpec) -> None:
    """Switching between new and reinstall drops the other mode's answers."""
    spec.__dict__.update(fresh.__dict__)


def run(ctx: Context, spec: HostSpec | None, changes: Changes, *, confirm: bool = True) -> HostSpec | None:
    """Walks the wizard; returns the evaluated spec. Answers that already
    name a host (--answers, resumed) start at the review. Without `confirm`
    (dry run, --yes-wipe) it ends after the review."""
    spec = spec or HostSpec()
    full = ["mode", "form", "disk", "review"] + (["confirm"] if confirm else [])
    steps = full if spec.host == "" else full[3:]
    i = 0
    while i < len(steps):
        step = steps[i]
        if step == "mode":
            if choose_mode(ctx, spec) is ui.BACK:
                return None
        elif step == "form":
            if not spec.new:
                i += 1
                continue
            if new_host_form(ctx, spec) is ui.BACK:
                i -= 1
                continue
        elif step == "disk":
            if pick_disk(ctx, spec) is ui.BACK:
                i -= 1 if spec.new else 2
                continue
        elif step == "review":
            if review(ctx, spec, changes) is ui.BACK:
                if "disk" not in steps:  # resumed answers: back means start over
                    steps, i = full, 0
                    continue
                i -= 1
                continue
        elif step == "confirm":
            if confirm_erase(spec) is ui.BACK:
                changes.rollback()
                i -= 1
                continue
        i += 1
    return spec


def resume_choice(repo: Repo) -> HostSpec | None:
    """Offer the answers of an earlier run, after a failed install or a crash."""
    dirty = repo.dirty_hosts()
    mounted = os.path.ismount("/mnt")
    previous = None
    if util.ANSWERS_FILE.is_file():
        try:
            previous = HostSpec.from_json(util.ANSWERS_FILE.read_text())
        except (ValueError, TypeError):
            previous = None
    if not (dirty or mounted or previous):
        return None
    intro = ["An earlier run left things behind:\n"]
    if dirty:
        intro.append("  changed host files in the clone: " + ", ".join(dirty) + "\n")
    if mounted:
        intro.append("  /mnt is still mounted\n")
    items: list = []
    if previous:
        items.append((f"Use the earlier answers ({previous.host} on {previous.disk})", "resume"))
    items += [("Start over (discard the clone's host changes, unmount /mnt)", "fresh")]
    choice = ui.menu("Earlier run", intro, items, back=False)
    if mounted:
        unmount()
    if dirty:
        repo.discard_host_changes()
    return previous if choice == "resume" else None


def unlock(repo: Repo) -> bool:
    while repo.locked():
        keys = find_keys()
        items = [(k, k) for k in keys] + [("Type a path...", ""), ("Quit", None)]
        choice = ui.menu(
            "Unlock the dotfiles",
            "nix/secrets is git-crypt encrypted and every host evaluates it. Pick the key "
            "(copy it to /home/nixos or plug in its USB stick, then come back here):",
            items,
            back=False,
        )
        if choice is None:
            return False
        if choice == "":
            choice = ui.text_input("Key path", None, "Path: ", "", lambda v: None if Path(v).is_file() else "No such file.")
            if choice is ui.BACK:
                continue
        try:
            repo.unlock(choice)
        except util.CommandFailed as e:
            ui.message("Unlock failed", e.output or str(e))
    return True

