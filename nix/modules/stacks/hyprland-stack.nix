{ inputs, ... }:
{
  flake.modules.nixos.hyprlandStack =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
        hyprland
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
