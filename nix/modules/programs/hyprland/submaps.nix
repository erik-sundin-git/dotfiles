{ ... }:
{
  flake.modules.homeManager.hyprland =
    { config, lib, pkgs, mkModeNotif, ... }:
    let
      mod = "SUPER";

      launchNotif = mkModeNotif {
        modeTitle = "Launch";
        bindings = [
          { key = "e"; description = "emacs"; }
          { key = "l"; description = "librewolf"; }
          { key = "Esc/Spc"; description = "exit"; }
        ];
      };

      powerNotif = mkModeNotif {
        modeTitle = "Power";
        bindings = [
          { key = "h"; description = "hibernate"; }
          { key = "r"; description = "reboot"; }
          { key = "s"; description = "shutdown"; }
          { key = "q"; description = "exit hyprland"; }
          { key = "Esc/Spc"; description = "exit"; }
        ];
      };

      mkSubmap =
        { name, notif ? null, actions }:
        let
          mkExit =
            key:
            lib.optionalString (notif != null) "bind = , ${key}, exec, ${notif.exit}\n"
            + "bind = , ${key}, submap, reset\n";
          mkAction =
            {
              key,
              cmd,
              bindType ? "bind",
              dispatcher ? "exec",
              resetAfterAction ? true,
            }:
            lib.optionalString (notif != null) "bind = , ${key}, exec, ${notif.exit}\n"
            + "${bindType} = , ${key}, ${dispatcher}, ${cmd}\n"
            + lib.optionalString resetAfterAction "bind = , ${key}, submap, reset\n";
        in
        ''
          submap = ${name}
          ${lib.concatMapStrings mkAction actions}${mkExit "escape"}${mkExit "space"}submap = reset
        '';
    in
    {
      wayland.windowManager.hyprland.settings.bind = [
        "${mod}, I, exec, ${launchNotif.enter}"
        "${mod}, I, submap, launch"
        "${mod} SHIFT, P, exec, ${powerNotif.enter}"
        "${mod} SHIFT, P, submap, power"
        "${mod}, R, submap, resize"
      ];

      wayland.windowManager.hyprland.extraConfig =
        mkSubmap {
          name = "launch";
          notif = launchNotif;
          actions = [
            { key = "E"; cmd = "emacs"; }
            { key = "L"; cmd = "librewolf"; }
          ];
        }
        + mkSubmap {
          name = "power";
          notif = powerNotif;
          actions = [
            { key = "H"; cmd = "systemctl hibernate"; }
            { key = "R"; cmd = "systemctl reboot"; }
            { key = "S"; cmd = "systemctl poweroff"; }
            { key = "Q"; cmd = "uwsm stop"; }
          ];
        }
        + mkSubmap {
          name = "resize";
          actions = [
            { key = "H"; dispatcher = "resizeactive"; cmd = "-20 0"; bindType = "binde"; resetAfterAction = false; }
            { key = "J"; dispatcher = "resizeactive"; cmd = "0 20"; bindType = "binde"; resetAfterAction = false; }
            { key = "K"; dispatcher = "resizeactive"; cmd = "0 -20"; bindType = "binde"; resetAfterAction = false; }
            { key = "L"; dispatcher = "resizeactive"; cmd = "20 0"; bindType = "binde"; resetAfterAction = false; }
          ];
        };
    };
}
