{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      mkWmModes,
      swayBindingsData,
      ...
    }:
    let
      built = mkWmModes {
        inherit (config.wayland.windowManager.sway.config) modifier;
        modes = swayBindingsData.modes // config.swayExtraModes;
      };
    in
    {
      # Modes of modules that only some hosts import (emacs/youtube.nix), in
      # the shape of swayBindingsData.modes. sway-help lists them too; EXWM
      # does not see them.
      options.swayExtraModes = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
        description = "Extra sway modes, shaped like swayBindingsData.modes.";
      };

      config.wayland.windowManager.sway.config = {
        inherit (built) keybindings modes;
      };
    };
}
