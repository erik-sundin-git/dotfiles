{ inputs, ... }:
{
  den.aspects.nomad = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = with inputs.self.modules.nixos; [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480s
          laptopBaseProfile
          swayfxStack
          gaming
          virtManager
          intelGen9Graphics
        ];

        systemConstants.system.host = "nomad";
        system.stateVersion = "25.11";

        services.hardware.bolt.enable = true;

        # gaming without Steam: Battle.net (umu), GeForce NOW and Prism only
        programs.steam.enable = false;
        gaming.boltLauncher = false;

        # Sleep, then hibernate to the disk swap after 2 h (lid and idle)
        commonConfig.suspendThenHibernate = true;

        # Intel UHD 620 (Kaby Lake-R): drivers from intelGen9Graphics, plus
        # framebuffer compression and panel self refresh for battery life
        boot.kernelParams = [
          "i915.enable_fbc=1"
          "i915.enable_psr=1"
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

        # Home Assistant for the home LAN only. A forwarded connection never
        # passes the INPUT firewall, so without the RETURN below 8123 would be
        # open on every network nomad joins. The home /24 comes from nomad's
        # own address in hosts.nix.
        networking.nat = {
          enable = true;
          externalInterface = "wlp61s0";
          extraCommands =
            let
              octets = lib.splitString "." config.systemConstants.network.hosts.nomad.ip;
              homeNet = lib.concatStringsSep "." (lib.take 3 octets) + ".0/24";
            in
            ''
              iptables -w -t nat -I nixos-nat-pre -i wlp61s0 ! -s ${homeNet} -p tcp --dport 8123 -j RETURN
            '';
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
            mail
            emacsYoutube
            dellU2722d
          ];

          # Proton sync rollout, see programs/mail/mail.nix (5 = full two-way sync incl. spam)
          mailSync.stage = 5;

          # No LaTeX on nomad: texliveFull is several GB in the store
          emacs.texlive = false;

          systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone5/temp";
          selectedTheme = "ef-bio";
        };
      };
  };
}
