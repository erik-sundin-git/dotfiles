{ ... }:
{
  flake.modules.nixos.memory =
    { lib, ... }:
    {
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
        extraArgs = [
          "--avoid"
          "^(sway|Xwayland|pulseaudio|lightdm|java)$"
          "--prefer"
          "^(firefox|librewolf|chromium|electron)$"
        ];
      };
    };
}
