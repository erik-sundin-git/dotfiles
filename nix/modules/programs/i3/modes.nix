{ ... }:
{
  flake.modules.homeManager.i3 =
    {
      config,
      lib,
      mkWmModes,
      ...
    }:
    let
      # Same shape as swayBindingsData.modes; i3 has no gammastep toggle and
      # exits through i3-msg
      built = mkWmModes {
        inherit (config.xsession.windowManager.i3.config) modifier;
        exec = "exec --no-startup-id";
        modes = {
          launch = {
            entryKey = "i";
            title = "Launch";
            bindings = [
              { key = "e"; desc = "emacs"; action = "exec emacs"; }
              { key = "l"; desc = "librewolf"; action = "exec librewolf"; }
            ];
          };
          power = {
            entryKey = "p";
            entryMod = "Shift";
            title = "Power";
            bindings = [
              { key = "h"; desc = "hibernate"; action = "exec systemctl hibernate"; }
              { key = "r"; desc = "reboot"; action = "exec systemctl reboot"; }
              { key = "s"; desc = "shutdown"; action = "exec systemctl poweroff"; }
              { key = "e"; desc = "logout"; action = "exec i3-msg exit"; }
            ];
          };
          options = {
            entryKey = "o";
            title = "Options";
            bindings = [
              { key = "v"; desc = "toggle vpn"; action = "exec vpn-toggle"; }
            ];
          };
          resize = {
            entryKey = "r";
            title = "Resize";
            stayInMode = true;
            bindings = [
              { key = "h"; desc = "shrink width"; action = "resize shrink width 5 px or 2 ppt"; }
              { key = "j"; desc = "grow height"; action = "resize grow height 5 px or 2 ppt"; }
              { key = "k"; desc = "shrink height"; action = "resize shrink height 5 px or 2 ppt"; }
              { key = "l"; desc = "grow width"; action = "resize grow width 5 px or 2 ppt"; }
            ];
          };
        };
      };
    in
    {
      xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault built.keybindings;
      xsession.windowManager.i3.config.modes = built.modes;
    };
}
