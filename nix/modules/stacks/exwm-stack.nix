{ inputs, ... }:
{
  flake.installer.stacks.exwmStack = {
    label = "EXWM: Emacs as the window manager (X11)";
    order = 30;
    session = "x11";
  };

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
        gammastep
      ];
    };
}
