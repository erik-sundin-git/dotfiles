{ ... }:
{
  # Single source of truth for SwayFX bindings. keybindings.nix, modes.nix, and
  # packages.nix (sway-help) all derive from this. Adding a bind in one place
  # updates sway config + OSD mode popup + mod+F1 cheatsheet at once.
  #
  # Bind shape: { key; action; desc; mod ? true; }
  #   mod = true  → key is prefixed with the sway modifier (Mod4)
  #   mod = false → raw key (media keys, Print without mod, XF86*)
  flake.modules.homeManager.swayfx =
    { ... }:
    {
      _module.args.swayBindingsData = {
        sections = [
          {
            title = "General";
            binds = [
              { key = "Return";     action = "exec alacritty";        desc = "Terminal (alacritty)"; }
              { key = "d";          action = "exec wofi --show drun"; desc = "App launcher (wofi drun)"; }
              { key = "Shift+q";    action = "kill";                  desc = "Kill focused window"; }
              { key = "Shift+a";    action = "exec nix-add-package";  desc = "Add nix package (claude flow)"; }
              { key = "Ctrl+l";     action = "exec loginctl lock-session"; desc = "Lock screen"; }
              { key = "F1";         action = "exec sway-help";        desc = "This help menu"; }
            ];
          }
          {
            title = "Focus / move";
            binds = [
              { key = "h";          action = "focus left";  desc = "Focus left"; }
              { key = "j";          action = "focus down";  desc = "Focus down"; }
              { key = "k";          action = "focus up";    desc = "Focus up"; }
              { key = "l";          action = "focus right"; desc = "Focus right"; }
              { key = "Shift+h";    action = "move left";   desc = "Move window left"; }
              { key = "Shift+j";    action = "move down";   desc = "Move window down"; }
              { key = "Shift+k";    action = "move up";     desc = "Move window up"; }
              { key = "Shift+l";    action = "move right";  desc = "Move window right"; }
            ];
          }
          {
            title = "Split";
            binds = [
              { key = "b";          action = "splith"; desc = "Split horizontal"; }
              { key = "v";          action = "splitv"; desc = "Split vertical"; }
            ];
          }
          {
            title = "Workspaces";
            # Enumerated so descriptions render individually; also gives the help
            # renderer a chance to collapse them into a range line.
            binds =
              (map (i: {
                key = toString i;
                action = "workspace number ${toString i}";
                desc = "Switch to workspace ${toString i}";
              }) (builtins.genList (i: i + 1) 9))
              ++ (map (i: {
                key = "Shift+${toString i}";
                action = "move container to workspace number ${toString i}";
                desc = "Move window to workspace ${toString i}";
              }) (builtins.genList (i: i + 1) 9))
              ++ [
                { key = "m";       action = "workspace mail";                       desc = "Workspace: mail"; }
                { key = "Shift+m"; action = "move container to workspace mail";     desc = "Move window to mail workspace"; }
                { key = "e";       action = "workspace emacs";                      desc = "Workspace: emacs"; }
                { key = "Shift+e"; action = "move container to workspace emacs";    desc = "Move window to emacs workspace"; }
              ];
            # Compact summary shown in help instead of 18 numbered rows.
            helpSummary = [
              "mod+1..9            Switch to workspace N"
              "mod+Shift+1..9      Move window to workspace N"
              "mod+m / Shift+m     Workspace mail / move to mail"
              "mod+e / Shift+e     Workspace emacs / move to emacs"
            ];
          }
          {
            title = "Screenshots";
            binds = [
              { key = "Print";     mod = false; action = "exec screenshot-area"; desc = "Screenshot area"; }
              { key = "Print";                  action = "exec screenshot-full"; desc = "Screenshot full screen"; }
            ];
          }
          {
            title = "Media";
            binds = [
              { key = "XF86AudioRaiseVolume"; mod = false; action = "exec swayosd-client --output-volume raise";        desc = "Volume up"; }
              { key = "XF86AudioLowerVolume"; mod = false; action = "exec swayosd-client --output-volume lower";        desc = "Volume down"; }
              { key = "XF86AudioMute";        mod = false; action = "exec swayosd-client --output-volume mute-toggle";  desc = "Mute toggle"; }
            ];
          }
        ];

        # Laptop-only binds; keybindings.nix wraps them in `lib.optionalAttrs
        # isLaptop`, and sway-help includes them only when isLaptop.
        laptopSection = {
          title = "Laptop";
          binds = [
            { key = "XF86MonBrightnessUp";   mod = false; action = "exec swayosd-client --brightness raise";     desc = "Screen brightness up"; }
            { key = "XF86MonBrightnessDown"; mod = false; action = "exec swayosd-client --brightness lower";     desc = "Screen brightness down"; }
            { key = "XF86MonBrightnessUp";                action = "exec brightnessctl --device='*kbd*' set +1"; desc = "Keyboard backlight up"; }
            { key = "XF86MonBrightnessDown";              action = "exec brightnessctl --device='*kbd*' set 1-"; desc = "Keyboard backlight down"; }
          ];
        };

        modes = {
          launch = {
            entryKey = "i";
            entryMod = "";
            title = "Launch";
            bindings = [
              { key = "e"; desc = "emacs";     action = "exec emacs"; }
              { key = "l"; desc = "librewolf"; action = "exec librewolf"; }
            ];
          };
          power = {
            entryKey = "p";
            entryMod = "Shift";
            title = "Power";
            bindings = [
              { key = "h"; desc = "hibernate"; action = "exec systemctl hibernate"; }
              { key = "r"; desc = "reboot";    action = "exec systemctl reboot"; }
              { key = "s"; desc = "shutdown";  action = "exec systemctl poweroff"; }
              { key = "e"; desc = "logout";    action = "exec swaymsg exit"; }
            ];
          };
          options = {
            entryKey = "o";
            entryMod = "";
            title = "Options";
            bindings = [
              { key = "v"; desc = "toggle vpn"; action = "exec vpn-toggle"; }
            ];
          };
          resize = {
            entryKey = "r";
            entryMod = "";
            title = "Resize";
            # Stay in resize after each press so you can hold h/j/k/l.
            stayInMode = true;
            bindings = [
              { key = "h"; desc = "shrink width";  action = "resize shrink width 5 px or 2 ppt"; }
              { key = "j"; desc = "grow height";   action = "resize grow height 5 px or 2 ppt"; }
              { key = "k"; desc = "shrink height"; action = "resize shrink height 5 px or 2 ppt"; }
              { key = "l"; desc = "grow width";    action = "resize grow width 5 px or 2 ppt"; }
            ];
          };
        };
      };
    };
}
