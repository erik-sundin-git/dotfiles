{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      mkModeNotif,
      swayBindingsData,
      ...
    }:
    let
      modifier = config.wayland.windowManager.sway.config.modifier;

      # Build the OSD popup, entry bind, and inner mode attrset for one mode.
      buildMode = name: mode:
        let
          notif = mkModeNotif {
            modeTitle = mode.title;
            bindings = (map (b: { key = b.key; description = b.desc; }) mode.bindings)
              ++ [ { key = "Esc/Spc"; description = "exit"; } ];
          };
          exitAction = "exec ${notif.exit}; mode default";
          entryPrefix = if mode.entryMod == "" then "" else "${mode.entryMod}+";
          entryBind = lib.nameValuePair
            "${modifier}+${entryPrefix}${mode.entryKey}"
            "exec ${notif.enter}; mode ${name}";
          stay = mode.stayInMode or false;
          innerBinds = lib.listToAttrs (map (b:
            lib.nameValuePair b.key (
              if stay
              then b.action
              else "exec ${notif.exit}; ${b.action}; mode default"
            )
          ) mode.bindings);
          exitBinds = {
            "Escape" = exitAction;
            "space" = exitAction;
          };
        in
        {
          inherit entryBind;
          attrs = lib.nameValuePair name (exitBinds // innerBinds);
        };

      modeNames = builtins.attrNames swayBindingsData.modes;
      built = map (n: buildMode n swayBindingsData.modes.${n}) modeNames;
    in
    {
      wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault (
        lib.listToAttrs (map (m: m.entryBind) built)
      );

      wayland.windowManager.sway.config.modes = lib.listToAttrs (map (m: m.attrs) built);
    };
}
