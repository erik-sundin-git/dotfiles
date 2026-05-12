{ ... }:
{
  flake.modules.homeManager.gammastep =
    { config, ... }:
    {
      services.gammastep = {
        enable = true;
        latitude = config.systemConstants.latitude;
        longitude = config.systemConstants.longitude;
        temperature.day = 6500;
        temperature.night = 2500;
      };
    };
}
