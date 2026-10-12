{ den, inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      { config, pkgs, ... }:
      let
        sysConst = {
          type = "laptop";
          host = "nomad";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480s
          commonDesktop
          swayfxStack
          gaming
          pulseaudio
          virtManager
        ];

        systemConstants.system = sysConst;

        services.hardware.bolt.enable = true;

        # Intel UHD 620 (Kaby Lake-R): VA-API, GuC/HuC firmware, thermald
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
        services.thermald.enable = true;

        # Snappier on battery than TLP's default balance_power
        services.tlp.settings = {
          CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_performance";
          PLATFORM_PROFILE_ON_BAT = "balanced";
        };

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
          ];
          home.packages = [ pkgs.local.curseforge ];
          systemConstants.system = sysConst;
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
