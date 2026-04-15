{
  inputs,
  lib,
  config,
  ...
}:
{
  flake.modules.nixos.picom = {
    home-manager.sharedModules = [ inputs.self.modules.homeManager.picom ];

  };
  flake.modules.homeManager.picom = {
    services.picom = {
      enable = true;
      backend = "glx";

      # Fading
      fade = true;
      fadeDelta = 5;
      fadeSteps = [
        3.0e-2
        3.0e-2
      ];

      # Opacity
      inactiveOpacity = 1.0;
      opacityRules = [
        "85:class_g = 'Alacritty'"
        "75:class_g = 'Emacs'"
        "60:class_g = 'i3bar'"
      ];

      settings = {
        blur = {
          method = "gaussian";
          size = 10;
          deviation = 5.0;
        };
      };
    };
  };
}
