{ inputs, ... }:
{
  flake.modules.homeManager.i3Stack =
    { ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        i3
        polybar
        #        picom
        gtk
        redshift
        dunst
      ];
    };
}
