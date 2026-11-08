{ inputs, ... }:
{
  # Intel Gen9.5 iGPUs (UHD 620 Kaby Lake-R on nomad, UHD 630 Coffee Lake-H on
  # xps): VA-API and GuC/HuC firmware, plus the matching browser decode prefs.
  # nixos-hardware's common/gpu/intel (pulled in by the host's nixos-hardware
  # module) loads i915 in the initrd and declares hardware.intelgpu; this
  # picks the drivers for this generation instead of its defaults (i965,
  # Gen12+ compute).
  flake.modules.nixos.intelGen9Graphics =
    { pkgs, ... }:
    {
      hardware.intelgpu = {
        vaapiDriver = "intel-media-driver";
        computeRuntime = "legacy";
      };
      hardware.graphics.extraPackages = with pkgs; [ libvdpau-va-gl ];
      environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
      boot.kernelParams = [
        "i915.enable_guc=2"
        "i915.fastboot=1"
      ];
      home-manager.sharedModules = [ inputs.self.modules.homeManager.intelVideoDecode ];
    };
}
