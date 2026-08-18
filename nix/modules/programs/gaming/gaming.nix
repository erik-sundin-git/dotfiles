{ ... }:
{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vpl-gpu-rt
          libvdpau-va-gl
        ];
      };
      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.initrd.kernelModules = [ "i915" ];
      boot.kernelParams = [
        "i915.enable_guc=3"
        "i915.enable_fbc=1"
        "i915.enable_psr=1"
        "i915.fastboot=1"
      ];

      services.thermald.enable = true;

      zramSwap = {
        enable = true;
        memoryPercent = 50;
        algorithm = "zstd";
      };

      boot.kernel.sysctl."vm.max_map_count" = 2147483642;

      programs.gamemode.enable = true;

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      environment.systemPackages = with pkgs; [
        mangohud
        protonup-qt
        bolt-launcher
      ];
    };
}
