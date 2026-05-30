{ inputs, ... }:
{
  flake.modules.nixos.hyprlandStack =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
        hyprland
      ];
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.hyprlandStack
      ];
    };

  flake.modules.homeManager.hyprlandStack =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        hyprland
        waybar
        gtk
        dunst
        starship
        gammastep
      ];
    };
}
