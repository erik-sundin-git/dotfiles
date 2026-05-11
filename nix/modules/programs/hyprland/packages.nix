{ ... }:
{
  flake.modules.homeManager.hyprland =
    { config, lib, pkgs, ... }:
    let
      isLaptop = config.systemConstants.system.type == "laptop";

      screenshotArea = pkgs.writeShellScriptBin "screenshot-area" ''
        mkdir -p ~/Pictures/Screenshots
        f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
        ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | tee "$f" | ${pkgs.wl-clipboard}/bin/wl-copy
      '';

      screenshotFull = pkgs.writeShellScriptBin "screenshot-full" ''
        mkdir -p ~/Pictures/Screenshots
        f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
        ${pkgs.grim}/bin/grim - | tee "$f" | ${pkgs.wl-clipboard}/bin/wl-copy
      '';
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
        pkgs.hyprpaper
        pkgs.blueman
        pkgs.nerd-fonts.jetbrains-mono
        screenshotArea
        screenshotFull
      ]
      ++ lib.optionals isLaptop [
        pkgs.brightnessctl
      ];
    };
}
