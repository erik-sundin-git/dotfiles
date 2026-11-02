{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      mkWmModes,
      swayBindingsData,
      ...
    }:
    let
      built = mkWmModes {
        inherit (config.wayland.windowManager.sway.config) modifier;
        inherit (swayBindingsData) modes;
      };
    in
    {
      wayland.windowManager.sway.config.keybindings = built.keybindings;
      wayland.windowManager.sway.config.modes = built.modes;
    };
}
