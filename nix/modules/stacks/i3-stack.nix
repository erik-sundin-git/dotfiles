{ inputs, ... }:
{
  flake.modules.nixos.i3Stack =
    { ... }:
    {
      imports = with inputs.self.modules.nixos; [
        bluetooth
        i3
      ];
    };

  flake.modules.homeManager.i3Stack =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        bluetooth
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
