{ ... }:

{
  flake.modules.homeManager.waybar-bar =
    { ... }:
    {
      programs.waybar.settings.mainBar = {
        layer = "bottom";
        position = "top";
        height = 30;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/submap"
        ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "tray"
          "custom/spotify"
          "custom/airpods"
          "custom/storage"
          "pulseaudio"
          "network"
          "battery"
          "clock"
        ];
      };
    };
}
