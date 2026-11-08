{ ... }:
{
  flake.modules.nixos.nixDaemon =
    { ... }:
    {
      # Builds yield CPU to interactive work. "batch" rather than "idle" so a
      # rebuild still progresses while a game saturates the CPU. No
      # daemonIOSchedClass: NVMe uses the "none" scheduler, which ignores ionice.
      nix.daemonCPUSchedPolicy = "batch";

      # Weekly hardlink dedup instead of auto-optimise-store, which slows every
      # store write (nix.optimise.dates defaults to daily)
      nix.optimise.automatic = true;
      # After nh clean (weekly, Mon 00:00): no hashing paths GC is about to drop
      nix.optimise.dates = [ "Mon 03:00" ];
      systemd.services.nix-optimise = {
        after = [ "nh-clean.service" ];
        # Holds when there is no battery at all (desktops)
        unitConfig.ConditionACPower = true;
        # The timer is Persistent, so a missed run catches up while the laptop
        # is in use, hashing the whole store (~50 GB read). Idle CPU priority,
        # and a cap on its page cache so it doesn't push apps out to zram. No
        # IOSchedulingClass: NVMe's "none" scheduler ignores it.
        serviceConfig = {
          CPUSchedulingPolicy = "idle";
          MemoryHigh = "2G";
        };
      };

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      nix.channel.enable = false;

      nix.settings = {
        download-buffer-size = 268435456; # 256 MiB; the 64 MiB default stalls big substitutions
        # Roaming laptops: an unreachable cache fails fast and builds locally
        # instead of hanging on the OS TCP timeout per query
        connect-timeout = 5;
        fallback = true;
        # GC during builds when the disk runs low, not only from nh clean
        min-free = 5 * 1024 * 1024 * 1024;
        max-free = 20 * 1024 * 1024 * 1024;
        # cache.nixos.org is already the default substituter
        extra-substituters = [ "https://nix-community.cachix.org" ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
