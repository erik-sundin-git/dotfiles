{ inputs, ... }:
{
  flake.installer.stacks.swayfxStack = {
    label = "SwayFX (Wayland)";
    order = 10;
    default = true;
    session = "wayland";
  };

  flake.modules.nixos.swayfxStack =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
        swayfx
      ];
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.swayfxStack
      ];
    };

  flake.modules.homeManager.swayfxStack =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        swayfx
        alacritty
        swayLock
        waybar
        wofi
        gtk
        dunst
        starship
        gammastep
      ];
    };
}
