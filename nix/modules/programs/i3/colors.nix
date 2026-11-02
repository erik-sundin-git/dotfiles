{ ... }:
{
  flake.modules.homeManager.i3 =
    { config, mkWmColors, ... }:
    {
      xsession.windowManager.i3.config.colors = mkWmColors config.theme;
    };
}
