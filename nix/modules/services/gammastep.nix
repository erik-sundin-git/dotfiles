{ ... }:
{
  flake.modules.homeManager.gammastep =
    { ... }:
    {
      services.gammastep = {
        enable = true;
        dawnTime = "07:00";
        duskTime = "21:00";
        temperature.day = 6500;
        temperature.night = 2500;
      };
    };
}
