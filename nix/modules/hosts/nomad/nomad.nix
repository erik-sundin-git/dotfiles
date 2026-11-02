{ inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { config, pkgs, ... }:
      {
        imports = with inputs.self.modules.nixos; [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480s
          laptopBaseProfile
          swayfxStack
          gaming
          virtManager
        ];

        systemConstants.system.host = "nomad";
        system.stateVersion = "25.11";

        services.hardware.bolt.enable = true;

        # Intel UHD 620 (Kaby Lake-R): VA-API, GuC/HuC firmware. nixos-hardware's
        # common/gpu/intel already loads i915 in the initrd; pick the drivers
        # for this generation instead of its defaults (i965, Gen12+ compute).
        hardware.intelgpu = {
          vaapiDriver = "intel-media-driver";
          computeRuntime = "legacy";
        };
        hardware.graphics.extraPackages = with pkgs; [ libvdpau-va-gl ];
        environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
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
            {
              destination = "${config.systemConstants.network.hosts.hass-vm.ip}:8123";
              proto = "tcp";
              sourcePort = 8123;
            }
          ];
        };

        home-manager.users.erik = {
          imports = with inputs.self.modules.homeManager; [
            gh
            chromium
            gtnhBackup
            emacsYoutube
            intelVideoDecode
          ];

          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone5/temp";
          selectedTheme = "ef-bio";

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
