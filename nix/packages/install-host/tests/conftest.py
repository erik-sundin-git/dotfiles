import pytest

from install_host.spec import Options

# Shaped like `nix eval --json .#installer`
INSTALLER = {
    "schemaVersion": 1,
    "stateVersion": "26.05",
    "profiles": {
        "laptopBaseProfile": {"type": "laptop", "label": "Laptop", "order": 10, "stacks": True},
        "desktopBaseProfile": {"type": "desktop", "label": "Desktop", "order": 20, "stacks": True},
        "serverProfile": {"type": "server", "label": "Server", "order": 30, "stacks": False},
        "vmProfile": {"type": "desktop", "label": "VM", "order": 40, "stacks": False},
    },
    "stacks": {
        "swayfxStack": {"label": "SwayFX", "order": 10, "default": True, "session": "wayland", "experimental": False},
        "i3Stack": {"label": "i3", "order": 20, "default": False, "session": "x11", "experimental": False},
        "hyprlandStack": {"label": "Hyprland", "order": 90, "default": False, "session": "wayland", "experimental": True},
    },
    "features": {
        "gaming": {"label": "Gaming", "order": 10, "profiles": ["laptopBaseProfile", "desktopBaseProfile"]},
        "virtManager": {"label": "libvirt", "order": 20, "profiles": ["laptopBaseProfile", "desktopBaseProfile"]},
    },
    "homeModules": {
        "gh": {"label": "gh", "order": 10, "profiles": ["laptopBaseProfile", "desktopBaseProfile", "serverProfile"]},
        "chromium": {"label": "Chromium", "order": 20, "profiles": ["laptopBaseProfile", "desktopBaseProfile"]},
    },
    "themes": ["catppuccin", "ef-bio", "onedark"],
    "defaultTheme": "onedark",
    "nixosHardware": [
        "dell-xps-15-7590",
        "dell-xps-15-7590-nvidia",
        "dell-xps-15-9570",
        "dell-xps-15-9570-intel",
        "dell-xps-15-9570-nvidia",
        "dell-xps-13-9370",
        "lenovo-thinkpad-t480",
        "lenovo-thinkpad-t480s",
        "lenovo-thinkpad-x1-6th-gen",
        "framework-13-7040-amd",
    ],
}


@pytest.fixture
def opts():
    return Options(INSTALLER)
