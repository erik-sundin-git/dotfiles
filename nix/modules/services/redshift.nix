{ ... }:
{
  flake.modules.homeManager.redshift =
    { config, ... }:
    {
      services.redshift = {
        enable = true;
        latitude = config.systemConstants.latitude;
        longitude = config.systemConstants.longitude;
        temperature.day = 6500;
        temperature.night = 2500;
      };
    };
}
