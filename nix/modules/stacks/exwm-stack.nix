{ inputs, ... }:
{
  flake.modules.nixos.exwmStack =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
        exwm
      ];
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.exwmStack
      ];
    };

  # No waybar, wofi or swayosd (Emacs draws the bar and menus), no picom (no
  # theming yet), no borders or gaps.
  flake.modules.homeManager.exwmStack =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        exwm
        i3Lock
        gtk
        dunst
        starship
        gammastep
      ];
    };
}
