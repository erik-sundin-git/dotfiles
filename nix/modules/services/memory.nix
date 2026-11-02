{ ... }:
{
  flake.modules.nixos.memory =
    { config, lib, ... }:
    {
      options.memory.earlyoomAvoid = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = ''
          Process names (regexps over /proc/<pid>/comm, 15 chars max) earlyoom
          never kills. Modules append to it, e.g. EXWM adds Emacs and the X
          server.
        '';
      };

      config = {
        # zram first (prio 5); the disk swap partition stays as overflow and hibernate target
        zramSwap = {
          enable = true;
          memoryPercent = 50;
          algorithm = "zstd";
        };

        # Tuning for swap-on-zram: swapping is cheap, readahead is pointless
        boot.kernel.sysctl = {
          "vm.swappiness" = lib.mkDefault 180;
          "vm.page-cluster" = lib.mkDefault 0;
          "vm.watermark_boost_factor" = lib.mkDefault 0;
          "vm.watermark_scale_factor" = lib.mkDefault 125;
        };

        # Session plumbing frees almost nothing when killed but takes the
        # desktop with it: dbus-broker-lau is the user-bus launcher, and
        # wrapped binaries show up as .<name>-wrapped. The browsers are avoided
        # too: the main process is .firefox-wrappe/.librewolf-wrap, its
        # children "Isolated Web Co", "Web Content", "Privileged Cont" and
        # "WebExtensions".
        memory.earlyoomAvoid = [
          "sway"
          "Xwayland"
          "pulseaudio"
          "lightdm"
          "java"
          "systemd"
          "dbus-broker"
          "dbus-broker-lau"
          "\\.waybar-wrapped"
          "\\.dunst-wrapped"
          "\\.swayosd-server"
          "\\.xdg-desktop-po"
          "firefox"
          "librewolf"
          "\\.firefox-wrappe"
          "\\.librewolf-wrap"
          "Isolated.Web.Co"
          "Web.Content"
          "Privileged.Cont"
          "WebExtensions"
        ];

        # earlyoom kills single processes. Not systemd-oomd user slices: sway is
        # started by LightDM, so apps share its session scope and oomd would take
        # the whole desktop down with them.
        services.earlyoom = {
          enable = true;
          freeMemThreshold = 5;
          # Fire once zram is used up, before the disk swap. zram is half of RAM
          # and the disk partition is about RAM-sized, so zram is ~30% of all
          # swap. 100 (ignore swap) fired with zram still empty and killed
          # hundreds of processes a day.
          freeSwapThreshold = 70;
          # earlyoom honours a single --avoid, so the list is joined here.
          # steamwebhelper respawns, so it goes first.
          extraArgs = [
            "--avoid"
            "^(${lib.concatStringsSep "|" config.memory.earlyoomAvoid})$"
            "--prefer"
            "^(chromium|electron|steamwebhelper)$"
          ];
          enableNotifications = true;
        };
      };
    };
}
