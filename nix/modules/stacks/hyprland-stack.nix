{ inputs, ... }:
{
  flake.installer.stacks.hyprlandStack = {
    label = "Hyprland (Wayland)";
    order = 90;
    session = "wayland";
    experimental = true;
  };

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
        alacritty
        hyprlandLock
        waybar
        wofi
        gtk
        dunst
        starship
        gammastep
      ];
    };
}
