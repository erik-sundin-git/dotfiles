{ inputs, ... }:
{
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
        polybar
        picom
        gtk
        redshift
        dunst
        starship
      ];
    };
}
