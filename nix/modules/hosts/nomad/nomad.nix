{ den, inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { config, pkgs, ... }:
      {
        imports = with inputs.self.modules.nixos; [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480s
          laptopProfile
          gaming
          virtManager
        ];

        systemConstants.system.host = "nomad";

        services.hardware.bolt.enable = true;

        # Intel UHD 620 (Kaby Lake-R): VA-API, GuC/HuC firmware
        hardware.graphics.extraPackages = with pkgs; [
          intel-media-driver
          libvdpau-va-gl
        ];
        environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
        boot.initrd.kernelModules = [ "i915" ];
        boot.kernelParams = [
          "i915.enable_guc=2"
          "i915.enable_fbc=1"
          "i915.enable_psr=1"
          "i915.fastboot=1"
        ];
        # throttled (from nixos-hardware) owns the power limits; thermald
        # would fight it over them
        services.thermald.enable = false;

        # Snappier on battery than TLP's default balance_power. No
        # PLATFORM_PROFILE_*: this firmware has no platform_profile.
        services.tlp.settings = {
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
        };

        # For benchmarking throttled's power limits
        environment.systemPackages = [
          config.boot.kernelPackages.turbostat
          pkgs.stress-ng
        ];

        networking.nat = {
          enable = true;
          externalInterface = "wlp61s0";
          forwardPorts = [
            { destination = "${config.systemConstants.network.hosts.hass-vm.ip}:8123"; proto = "tcp"; sourcePort = 8123; }
          ];
        };

        home-manager.users.erik =
          { pkgs, ... }:
          {
          imports = with inputs.self.modules.homeManager; [
            gh
            chromium
            geforcenow
            gtnhBackup
          ];
          home.packages = [ pkgs.local.curseforge ];
          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone5/temp";
          selectedTheme = "catppuccin";

          wayland.windowManager.sway.config.output = {
            "Dell Inc. DELL U2722D 3JYTCH3" = {
              mode = "2560x1440";
              position = "0,0";
            };
            "eDP-1".position = "2560,0";
          };
        };
      };
  };
}
