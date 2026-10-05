{ ... }:
{
  flake.modules.nixos.geforcenow = {
    services.flatpak.enable = true;
  };

  flake.modules.homeManager.geforcenow =
    { pkgs, lib, ... }:
    {
      home.packages = [ pkgs.local.geforcenow ];

      home.activation.geforcenow = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists flathub \
          https://dl.flathub.org/repo/flathub.flatpakrepo || true
        $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak remote-add --user --if-not-exists GeForceNOW \
          https://international.download.nvidia.com/GFNLinux/flatpak/geforcenow.flatpakrepo || true
        $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install --user --noninteractive \
          flathub org.freedesktop.Platform//24.08 || true
        $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install --user --noninteractive \
          GeForceNOW com.nvidia.geforcenow || true
      '';
    };
}
