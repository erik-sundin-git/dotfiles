{ ... }:
{
  den.aspects.xps.nixos =
    { config, pkgs, ... }:
    {
      # Keep the display and session awake while docked or charging. The
      # session idle commands also check AC state before blanking or sleeping.
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

      home-manager.users.erik.services.poweralertd.enable = false;

      # For finding a stable undervolt and power limits (see nomad.nix)
      environment.systemPackages = [
        config.boot.kernelPackages.turbostat
        pkgs.stress-ng
        pkgs.undervolt
      ];

      # Core/cache undervolt. -125 mV passed stress-ng (cpu + AVX matrix with
      # --verify) and normal use. Needs "Overclocking Lock" (Setup
      # variable, offset 0x789 on BIOS 1.12.0) cleared and SGX off; a BIOS
      # update sets both back, and then this fails ("set …, read 0.0") until
      # they're cleared again. Core and cache share a voltage plane, so they
      # get the same offset (services.undervolt has no cache option).
      # Reapplied after resume: deep sleep resets the MSR.
      systemd.services.undervolt = {
        description = "Undervolt CPU core/cache";
        wantedBy = [
          "multi-user.target"
          "post-resume.target"
        ];
        after = [ "post-resume.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.undervolt}/bin/undervolt --core -125 --cache -125
        '';
      };

      # This firmware has platform_profile (cool/quiet/balanced/performance).
      # balance_performance still boosts under load; "performance" pinned
      # every core near 4 GHz and ran hot on this cooler. TLP's default
      # RUNTIME_PM_ON_AC=on would keep the 1650 powered whenever plugged in.
      services.tlp.settings = {
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "balanced";
        # Explicit, so a stale no_turbo=1 (e.g. from `tlp power-saver`)
        # doesn't survive the next TLP run
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1;
        RUNTIME_PM_ON_AC = "auto";
      };

      # While a game runs under gamemode (`gamemoderun … %command%`): Dell's
      # "performance" profile, and thermald stopped, since its --adaptive
      # tables hold PL1 at 20 W ("balanced" lost a lot of fps in BO3). The
      # firmware's own thermal limits still apply. Too hot to keep on always.
      systemd.services.game-performance = {
        description = "Performance platform profile while gaming";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          ${config.systemd.package}/bin/systemctl stop --no-block thermald.service
          echo performance > /sys/firmware/acpi/platform_profile
        '';
        postStop = ''
          echo ${config.services.tlp.settings.PLATFORM_PROFILE_ON_AC} > /sys/firmware/acpi/platform_profile
          ${config.systemd.package}/bin/systemctl start --no-block thermald.service
        '';
      };

      # gamemoded runs as erik, so it may start/stop only that unit
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "game-performance.service" &&
              subject.user == "erik") {
            var verb = action.lookup("verb");
            if (verb == "start" || verb == "stop") return polkit.Result.YES;
          }
        });
      '';

      programs.gamemode.settings = {
        # Keep intel_pstate on powersave + EPP: gamemode's default
        # "performance" governor pins every core near 4 GHz (see TLP above)
        general.desiredgov = "powersave";
        custom = {
          start = "${config.systemd.package}/bin/systemctl start game-performance.service";
          end = "${config.systemd.package}/bin/systemctl stop game-performance.service";
        };
      };

    };
}
