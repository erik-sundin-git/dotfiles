{ ... }:

{
  flake.modules.homeManager.hyprland-hyprpaper =
    { ... }:
    {
      services.hyprpaper = {
        enable = true;
        settings = {
          wallpaper = [
            {
              monitor = "eDP-1";
              path = "~/Pictures/saturn.png";
              fit_mode = "cover";
            }
          ];
        };
      };
    };
}
