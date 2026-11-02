{ ... }:
{
  flake.modules.homeManager.swayfx =
    { config, mkWmColors, ... }:
    {
      wayland.windowManager.sway.config.colors = mkWmColors config.theme;
    };
}
