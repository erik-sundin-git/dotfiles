{ ... }:
{
  flake.modules.nixos.pulseaudio =
    { pkgs, ... }:
    {
      services.pulseaudio = {
        enable = true;
        package = pkgs.pulseaudioFull;
      };
    };
}
