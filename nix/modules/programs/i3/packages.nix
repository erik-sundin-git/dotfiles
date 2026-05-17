{ ... }:
{
  flake.modules.homeManager.i3 =
    {
      pkgs,
      config,
      lib,
      mkScreenshot,
      ...
    }:
    {
      home.packages = [
        pkgs.dmenu
        pkgs.nitrogen
        pkgs.maim
        pkgs.xclip
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.xdg-desktop-portal
        pkgs.xdg-desktop-portal-gtk
        (mkScreenshot {
          name = "screenshot-area";
          args = "-s";
        })
        (mkScreenshot { name = "screenshot-full"; })
      ]
      ++ lib.optionals (config.systemConstants.system.type == "laptop") [
        pkgs.brightnessctl
      ];
    };
}
