{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      isLaptop,
      swayBindingsData,
      ...
    }:
    let
      modifier = config.wayland.windowManager.sway.config.modifier;

      # A single bind → { name = sway key syntax; value = sway action; }
      bindToAttr = b:
        let
          withMod = b.mod or true;
          name = if withMod then "${modifier}+${b.key}" else b.key;
        in
        lib.nameValuePair name b.action;

      allBinds =
        lib.concatMap (s: s.binds) swayBindingsData.sections;
      laptopBinds = swayBindingsData.laptopSection.binds;
    in
    {
      wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault (
        lib.listToAttrs (map bindToAttr allBinds)
        // lib.optionalAttrs isLaptop (lib.listToAttrs (map bindToAttr laptopBinds))
      );
    };
}
