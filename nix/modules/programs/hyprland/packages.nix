{ ... }:
{
  flake.modules.homeManager.hyprland =
    { config, lib, pkgs, mkShot, ... }:
    let
      isLaptop = config.systemConstants.system.type == "laptop";

      screenshotArea = mkShot {
        name = "screenshot-area";
        captureCmd = "${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" -";
      };
      screenshotFull = mkShot {
        name = "screenshot-full";
        captureCmd = "${pkgs.grim}/bin/grim -";
      };
    in
    {
      home.packages = [
        pkgs.wofi
        pkgs.jq
        pkgs.pavucontrol
        pkgs.pulseaudio
        pkgs.swayosd
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.swaybg
        pkgs.hyprpolkitagent
        pkgs.nerd-fonts.jetbrains-mono
        screenshotArea
        screenshotFull
      ]
      ++ lib.optionals isLaptop [
        pkgs.brightnessctl
      ];
    };
}
