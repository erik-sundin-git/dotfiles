{ inputs, ... }:
{
  flake.installer.stacks.swayfxStack = {
    label = "SwayFX (Wayland)";
    order = 10;
    default = true;
    session = "wayland";
  };

  flake.modules.nixos.swayfxStack =
    { lib, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
        swayfx
      ];

      xdg.mime.defaultApplications = lib.genAttrs [
        "image/avif"
        "image/bmp"
        "image/gif"
        "image/jpeg"
        "image/png"
        "image/svg+xml"
        "image/tiff"
        "image/webp"
      ] (_: "swayimg.desktop");

      # The foot server holds every footclient window: killing it closes them all
      memory.earlyoomAvoid = [ "foot" ];

      home-manager.sharedModules = [
        inputs.self.modules.homeManager.swayfxStack
      ];
    };

  flake.modules.homeManager.swayfxStack =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.swayimg ];

      imports = with inputs.self.modules.homeManager; [
        swayfx
        foot
        swayLock
        waybar
        fuzzel
        gtk
        dunst
        gammastep
      ];
    };
}
