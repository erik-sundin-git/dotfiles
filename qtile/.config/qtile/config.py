# Erik Sundin
# Qtile config
#
# colorpalette: https://coolors.co/d1f0b1-b6cb9e-92b4a7-8c8a93-81667a

from libqtile import bar, layout, qtile, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
import os
import subprocess
import socket
import colors

################
### Settings ###
################

mod = "mod4"
terminal = "alacritty"
# terminal = "kitty"
browser = "qutebrowser"
menu = "rofi -show drun"
FONT_SIZE = 14

desktop = "Thinkpad"

# Bar settings
bar_size = 35
widget_padding = 10

##############
### Config ###
##############

@hook.subscribe.startup_once
def autostart():
    with open("/tmp/qtile-autostart.log", "w") as f:
        f.write("Autostart script triggered\n")
    subprocess.Popen(['/bin/bash', os.path.expanduser('~/.config/qtile/autostart.sh')])

def get_vendor_info():
    path = "/sys/class/dmi/id/sys_vendor"
    try:
        with open(path, "r") as file:
            vendor_info = file.read().strip()
    except FileNotFoundError:
        vendor_info = "Unknown"
    except PermissionError:
        vendor_info = "Permission Denied"

    return vendor_info


host_name = get_vendor_info()


def battery_widget():
    w = widget.Battery(
        low_foreground="000000",
        low_background=colors.red_1,
        format="{char}{percent: 2.0%}",
        low_percentage=0.15,
    )
    return w


def create_bars() -> bar.Bar:
    """
    Create bar
    """
    newBar = bar.Bar(
        [

            widget.CurrentLayout(fontsize=FONT_SIZE, padding=widget_padding),
            widget.TextBox(text="|", padding=widget_padding, fontsize=FONT_SIZEl+10),
            widget.GroupBox(fontsize=FONT_SIZE),
            widget.Spacer(),
            widget.Clock(format="%H:%M", padding=widget_padding, fontsize=FONT_SIZE),
            widget.Spacer(),
            widget.Memory(
                padding=widget_padding
            ),
            battery_widget(),
            #            widget.Systray(),
            widget.Clock(format="%y-%m-%d %a", padding=widget_padding),
        ],
        bar_size,
        background="141414.8",
        border_width=[0, 0, 0, 0],
        margin=[2, 2, 2, 2],  # Top, Right, Bottom, Left,
        border_color=["000000", "000000", "000000", "000000"],
    )
    return newBar


# END create_bars()

keys = [
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
        # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(
        [mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"
    ),
    Key(
        [mod, "shift"],
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key(
        [mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"
    ),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "d", lazy.spawn(menu), desc="Launch menu"),
    Key([mod, "shift"], "f", lazy.spawn(browser), desc="Launch browser"),
    # Toggle between different layouts as defined below
    Key([mod], "tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key(
        [mod],
        "t",
        lazy.window.toggle_floating(),
        desc="Toggle floating on the focused window",
    ),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
    # screenstuff
    Key(
        [mod, "shift"],
        "Right",  # Example key combination (Ctrl + Left Arrow)
        lazy.window.toscreen(0),  # Move window to screen 1
        lazy.to_screen(0),
        desc="Move window to screen 1",
    ),
    Key(
        [mod, "shift"],
        "Left",  # Example key combination (Ctrl + Right Arrow)
        lazy.window.toscreen(1),  # Move window to screen 0
        lazy.to_screen(1),
        desc="Move window to screen 0",
    ),
    Key([mod], "right", lazy.to_screen(0), desc="Move focus to next monitor"),
    Key([mod], "left", lazy.to_screen(1), desc="Move focus to previous monitor"),
    Key([mod], "space", lazy.next_screen(), desc="Move focues to the next screen"),
    Key([mod, "control"], "right", lazy.layout.next_split()),
    Key([mod, "control"], "left", lazy.layout.next_split()),
]

# Add key bindings to switch VTs in Wayland.
# We can't check qtile.core.name in default config as it is loaded before qtile is started
# We therefore defer the check until the key binding is run by using .when(func=...)
for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )


groups = [
    Group("1"),
    Group("2"),
    Group("3", label="web"),
    Group("4", matches=Match(wm_class="emacs"), label="emacs"),
    Group(
        "5",
        matches=[Match(wm_class="pavucontrol"), Match(title="ncspot")],
        label="music",
    ),
    Group("6", matches=Match(wm_class="virt-manager"), label="vm"),
    Group("7", label="email"),
    Group("8"),
    Group("9"),
]

for i in groups:
    keys.extend(
        [
            # mod1 + group number = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + group number = switch to & move focused window to group
            #:Key(
            #    [mod, "shift"],
            #   i.name,
            #    lazy.window.togroup(i.name, switch_group=True),
            #   desc="Switch to & move focused window to group {}".format(i.name),
            # ),
            # # mod1 + shift + group number = move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name),
                desc="move focused window to group {}".format(i.name),
            ),
        ]
    )
    #######################
    ### Group shortcuts ###
    #######################

    keys.extend([
        Key([mod], "m", lazy.group[groups[6].name].toscreen()), # email
        Key([mod], "e", lazy.group[groups[3].name].toscreen()),  # emacs
        Key([mod], "b", lazy.group[groups[2].name].toscreen())  # Browser
    ])



layouts = [
    layout.Columns(border_focus="#000000", margin=2, border_width=0),
    layout.MonadTall(border_focus="#28464B", margin=4),
    layout.Max(),
    # layout.MonadWide(border_focus="#28464B"),
    # layout.Stack(num_stacks=2),
    # layout.Bsp
    # layout.Matrix(),
    layout.MonadThreeCol(ratio=0.6),
    # layout.RatioTile(),
    # layout.Tile(),
    layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font="sans",
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()


screens = [
    Screen(
        top=create_bars(),
    ),
    Screen(
         top=create_bars(),
    ),
]

floating_layout = layout.Floating(
    border_focus="28464B",
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ],
)


auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
