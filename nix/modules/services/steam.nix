{ ... }:
{
  flake.modules.nixos.steam =
    { ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };
}
