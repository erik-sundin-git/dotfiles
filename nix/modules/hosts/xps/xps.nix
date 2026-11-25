# Dell XPS 15 7590. The rest of the host is in this directory: the GTX 1650
# (nvidia.nix) and power (power.nix).
{ inputs, ... }:
{
  den.aspects.xps.nixos =
    { lib, pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        inputs.nixos-hardware.nixosModules.dell-xps-15-7590-nvidia
        laptopBaseProfile
        swayfxStack
        gaming
        intelGen9Graphics
      ];

      systemConstants.system.host = "xps";
      system.stateVersion = "26.05";

      services.hardware.bolt.enable = true;

      # Reachable over ssh, unlike the other laptops (commonConfig closes 22)
      services.openssh.openFirewall = true;
      services.openssh.settings.PasswordAuthentication = lib.mkForce true;

      # GE-Proton sets WINENTSYNC=1 but falls back to fsync (wineserver
      # burning CPU) when /dev/ntsync is missing. The module isn't autoloaded,
      # and the node is root-only without a rule; uaccess gives it to the
      # seat user.
      boot.kernelModules = [ "ntsync" ];
      services.udev.extraRules = ''
        KERNEL=="ntsync", TAG+="uaccess"
      '';

      # Readable console on the 4K panel (the 7590 module sets earlySetup)
      console = {
        font = "ter-v32n";
        packages = [ pkgs.terminus_font ];
      };

      home-manager.users.erik = {
        imports = with inputs.self.modules.homeManager; [
          gh
          dellU2722d
          chromium
          emacsYoutube
        ];

        selectedTheme = "ef-bio";
        # x86_pkg_temp
        systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone12/temp";
      };
    };
}
