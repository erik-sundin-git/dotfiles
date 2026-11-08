{ ... }:
{
  flake.modules.homeManager.picom =
    { config, lib, ... }:
    let
      t = config.theme;
    in
    {
      # No opacityRules: alacritty (window.opacity) and Emacs (alpha-background,
      # nix-theme.el) make their own backgrounds translucent, so a picom rule
      # on top multiplied the two (0.9 became ~0.81) and faded the text too.
      services.picom = {
        enable = true;
        inactiveOpacity = 1;
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
