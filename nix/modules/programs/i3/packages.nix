{ ... }:
{
  flake.modules.homeManager.i3 =
    {
      pkgs,
      lib,
      mkScreenshot,
      isLaptop,
      ...
    }:
    {
      home.packages = [
        pkgs.dmenu
        pkgs.xclip
        (mkScreenshot {
          name = "screenshot-area";
          args = "-s";
        })
        (mkScreenshot { name = "screenshot-full"; })
      ]
      ++ lib.optionals isLaptop [
        pkgs.brightnessctl
      ];
    };
}
