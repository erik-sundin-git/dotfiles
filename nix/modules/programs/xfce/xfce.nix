{ ... }:
{
  flake.modules.nixos.xfce =
    { ... }:
    {
      services.xserver.desktopManager.xfce.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
    };
}
