{ ... }:
{
  flake.modules.homeManager.picom =
    { ... }:
    {
      services.picom = {
        enable = true;
        inactiveOpacity = 1;
        opacityRules = [
          "90:class_g = 'Alacritty'"
          "90:class_g = 'Emacs'"
        ];
        settings = {
          corner-radius = 0;
        };
      };
    };
}
