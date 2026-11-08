{ ... }:
{
  # The desk monitor (Dell U2722D) at 1440p, with the laptop panel to its
  # right. Imported by the laptops that dock to it (nomad, xps).
  flake.modules.homeManager.dellU2722d =
    { ... }:
    {
      wayland.windowManager.sway.config.output = {
        "Dell Inc. DELL U2722D 3JYTCH3" = {
          mode = "2560x1440";
          position = "0,0";
        };
        "eDP-1".position = "2560,0";
      };
    };
}
