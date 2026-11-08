{ inputs, ... }:
{
  flake.installer.stacks.i3Stack = {
    label = "i3 (X11)";
    order = 20;
    session = "x11";
  };

  flake.modules.nixos.i3Stack =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
        i3
      ];
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.i3Stack
      ];
    };

  flake.modules.homeManager.i3Stack =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        i3
        alacritty
        i3Lock
        polybar
        picom
        gtk
        gammastep
        dunst
        starship
      ];
    };
}
