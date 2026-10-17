{ ... }:
{
  flake.modules.nixos.nixDaemon =
    { ... }:
    {
      # Builds yield CPU to interactive work. "batch" rather than "idle" so a
      # rebuild still progresses while a game saturates the CPU. No
      # daemonIOSchedClass: NVMe uses the "none" scheduler, which ignores ionice.
      nix.daemonCPUSchedPolicy = "batch";

      # Weekly hardlink dedup instead of auto-optimise-store, which slows every store write
      nix.optimise.automatic = true;

      nix.settings = {
        download-buffer-size = 268435456; # 256 MiB; the 64 MiB default stalls big substitutions
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
