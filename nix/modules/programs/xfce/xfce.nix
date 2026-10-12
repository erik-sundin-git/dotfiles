{ ... }:
{
  flake.modules.nixos.xfce =
    { ... }:
    {
      services.xserver.desktopManager.xfce.enable = true;
    };
}
