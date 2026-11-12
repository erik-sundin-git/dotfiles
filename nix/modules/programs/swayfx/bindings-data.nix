{ ... }:
{
  # Single source of truth for SwayFX bindings. keybindings.nix, modes.nix, and
  # packages.nix (sway-help) all derive from this. Adding a bind in one place
  # updates sway config + OSD mode popup + mod+F1 cheatsheet at once.
  # keybindings.nix replaces HM's default binds rather than extending them, so
  # every bind sway has is listed here.
  #
  # homeManager.exwm and homeManager.i3 translate the same data into EXWM and
  # i3 binds (programs/exwm/keybindings.nix, programs/i3/keybindings.nix), so
  # a new action needs a mapping there too; the installer-exwmStack and
  # installer-i3Stack checks fail until it has one. Its own module (imported
  # by swayfx, exwm and i3) so the others can use it without sway; like
  # uiHelpers it sets _module.args and can't be imported twice in one host.
  #
  # Bind shape: { key; action; desc; mod ? true; }
  #   mod = true  → key is prefixed with the sway modifier (Mod4)
  #   mod = false → raw key (media keys, Print without mod, XF86*)
  flake.modules.homeManager.swayBindings =
    {
      lib,
      pkgs,
      swayBindingsData,
      ...
    }:
    let
      d = swayBindingsData;
      # Two binds on one key would otherwise just lose one in listToAttrs
      dups = keys: lib.unique (lib.filter (k: lib.count (x: x == k) keys > 1) keys);
      bindKey = b: if b.mod or true then "mod+${b.key}" else b.key;
      entryKey =
        m: "mod+" + lib.optionalString ((m.entryMod or "") != "") "${m.entryMod}+" + m.entryKey;
      globalDups = dups (
        map bindKey (lib.concatMap (s: s.binds) d.sections ++ d.laptopSection.binds)
        ++ lib.mapAttrsToList (_: entryKey) d.modes
      );
      # Escape and space leave every mode (mkWmModes)
      modeDups = lib.concatLists (
        lib.mapAttrsToList (
          name: m:
          map (k: "${name}: ${k}") (
            dups (
              map (b: b.key) m.bindings
              ++ [
                "Escape"
                "space"
              ]
            )
          )
        ) d.modes
      );
    in
    {
      assertions = [
        {
          assertion = globalDups == [ ];
          message = "swayBindingsData binds a key twice: ${toString globalDups}";
        }
        {
          assertion = modeDups == [ ];
          message = "swayBindingsData mode binds a key twice (Escape/space are reserved): ${toString modeDups}";
        }
      ];

      # The media keys below run playerctl. playerctld makes it act on the
      # player used last, not on whichever (often a browser tab) comes first.
      home.packages = [ pkgs.playerctl ];
      services.playerctld.enable = true;

      _module.args.swayBindingsData = {
        sections = [
          {
            title = "General";
            binds = [
              { key = "Return";     action = "exec footclient";       desc = "Terminal (foot)"; }
              { key = "Shift+Return"; action = "exec firefox";        desc = "Browser (firefox)"; }
              { key = "d";          action = "exec fuzzel";           desc = "App launcher (fuzzel)"; }
              { key = "Shift+q";    action = "kill";                  desc = "Kill focused window"; }
              { key = "Shift+a";    action = "exec nix-add-package";  desc = "Add nix package (claude flow)"; }
              { key = "c";          action = "exec claude-prompt";    desc = "Ask claude (quick prompt)"; }
              { key = "Ctrl+l";     action = "exec loginctl lock-session"; desc = "Lock screen"; }
              { key = "Shift+c";    action = "reload";                desc = "Reload sway config"; }
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
              { key = "Left";       action = "focus left";  desc = "Focus left (arrow)"; }
              { key = "Down";       action = "focus down";  desc = "Focus down (arrow)"; }
              { key = "Up";         action = "focus up";    desc = "Focus up (arrow)"; }
              { key = "Right";      action = "focus right"; desc = "Focus right (arrow)"; }
              { key = "Shift+Left"; action = "move left";   desc = "Move window left (arrow)"; }
              { key = "Shift+Down"; action = "move down";   desc = "Move window down (arrow)"; }
              { key = "Shift+Up";   action = "move up";     desc = "Move window up (arrow)"; }
              { key = "Shift+Right"; action = "move right"; desc = "Move window right (arrow)"; }
              { key = "Ctrl+Shift+Left";  action = "move workspace to output left";  desc = "Move workspace to left monitor"; }
              { key = "Ctrl+Shift+Right"; action = "move workspace to output right"; desc = "Move workspace to right monitor"; }
              { key = "a";          action = "focus parent"; desc = "Focus parent container"; }
              { key = "space";      action = "focus mode_toggle"; desc = "Toggle focus tiling/floating"; }
            ];
          }
          {
            title = "Split";
            binds = [
              { key = "b";          action = "splith"; desc = "Split horizontal"; }
              { key = "v";          action = "splitv"; desc = "Split vertical"; }
              { key = "t";          action = "layout toggle split"; desc = "Toggle split layout (leave tabbed/stacking)"; }
              { key = "s";          action = "layout stacking"; desc = "Stacking layout"; }
              { key = "w";          action = "layout tabbed"; desc = "Tabbed layout"; }
              { key = "f";          action = "fullscreen toggle"; desc = "Fullscreen"; }
              { key = "Shift+space"; action = "floating toggle"; desc = "Toggle floating"; }
              { key = "minus";      action = "scratchpad show"; desc = "Show scratchpad"; }
              { key = "Shift+minus"; action = "move scratchpad"; desc = "Move window to scratchpad"; }
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
                { key = "0";       action = "workspace number 10";                  desc = "Switch to workspace 10"; }
                { key = "Shift+0"; action = "move container to workspace number 10"; desc = "Move window to workspace 10"; }
                { key = "m";       action = "workspace mail";                       desc = "Workspace: mail"; }
                { key = "Shift+m"; action = "move container to workspace mail";     desc = "Move window to mail workspace"; }
              ];
            # Compact summary shown in help instead of 18 numbered rows.
            helpSummary = [
              "mod+1..9, 0         Switch to workspace N (0 = 10)"
              "mod+Shift+1..9, 0   Move window to workspace N"
              "mod+m / Shift+m     Workspace mail / move to mail"
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
              { key = "XF86AudioMicMute";     mod = false; action = "exec swayosd-client --input-volume mute-toggle";   desc = "Mic mute toggle"; }
              { key = "XF86AudioPlay";        mod = false; action = "exec playerctl play-pause"; desc = "Play/pause"; }
              { key = "XF86AudioNext";        mod = false; action = "exec playerctl next";       desc = "Next track"; }
              { key = "XF86AudioPrev";        mod = false; action = "exec playerctl previous";   desc = "Previous track"; }
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
            title = "Launch";
            bindings = [
              { key = "e"; desc = "emacs";     action = "exec emacs"; }
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
            title = "Options";
            bindings = [
              { key = "v"; desc = "toggle vpn"; action = "exec vpn-toggle"; }
              { key = "g"; desc = "toggle gammastep"; action = "exec gammastep-toggle"; }
            ];
          };
          resize = {
            entryKey = "r";
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
