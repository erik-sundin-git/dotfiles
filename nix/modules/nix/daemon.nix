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
      nix.optimise.dates = [ "weekly" ];

      nix.settings = {
        download-buffer-size = 268435456; # 256 MiB; the 64 MiB default stalls big substitutions
        # cache.nixos.org is already the default substituter
        extra-substituters = [ "https://nix-community.cachix.org" ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
