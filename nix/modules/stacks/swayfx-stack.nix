{ inputs, ... }:
{
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
        waybar
        gtk
        dunst
        starship
        gammastep
      ];
    };
}
