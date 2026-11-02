{ ... }:
{
  flake.modules.homeManager.picom =
    { config, lib, ... }:
    let
      t = config.theme;
      opacityPct = toString (builtins.floor (t.opacity * 100));
    in
    {
      services.picom = {
        enable = true;
        inactiveOpacity = 1;
        opacityRules = lib.optionals (t.opacity < 1.0) [
          "${opacityPct}:class_g = 'Alacritty'"
          "${opacityPct}:class_g = 'Emacs'"
        ];
        # Blur needs the glx backend
        backend = lib.mkIf t.blur "glx";
        settings = {
          corner-radius = t.rounding;
        }
        // lib.optionalAttrs t.blur {
          blur = {
            method = "dual_kawase";
            strength = 5;
          };
        };
      };
    };
}
