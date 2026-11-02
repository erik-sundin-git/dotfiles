{ inputs, ... }:
{
  den.aspects."xps".nixos =
    { lib, pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        # Base 7590 module (deep sleep, thermald, intel cpu/gpu, ssd) plus the
        # GTX 1650 as a PRIME offload GPU with fine-grained runtime PM
        inputs.nixos-hardware.nixosModules.dell-xps-15-7590-nvidia
        laptopProfile
        gaming
        ./_hardware-configuration.nix
      ];

      systemConstants.system.host = "xps";
      system.stateVersion = "26.05";

      services.hardware.bolt.enable = true;

      # Stable name for the iGPU: cardN changes between boots, and the by-path
      # names contain ':', the WLR_DRM_DEVICES separator
      services.udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
      '';

      # The stock nvidia-offload, plus re-enabling nvidia's EGL vendor, which
      # the sway session hides (see below)
      hardware.nvidia.prime.offload.enableOffloadCmd = lib.mkForce false;
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "nvidia-offload" ''
          unset __EGL_VENDOR_LIBRARY_FILENAMES
          export __NV_PRIME_RENDER_OFFLOAD=1
          export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export __VK_LAYER_NV_optimus=NVIDIA_only
          exec "$@"
        '')
      ];

      # gaming sets linuxPackages_latest (7.3), which nvidia 595 doesn't
      # build against yet; stay on the default kernel until it does
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

      # nixpkgs defaults to nvidia's new kernel suspend notifiers with 595 +
      # open modules; the first suspend with them never came back. Use the
      # nvidia-suspend/resume systemd services instead.
      hardware.nvidia.powerManagement.kernelSuspendNotifier = false;

      # Intel UHD 630 (Coffee Lake-H): VA-API and HuC firmware. Same Gen9.5
      # driver choices as nomad; nixos-hardware's defaults target newer GPUs.
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

      # This firmware has platform_profile (cool/quiet/balanced/performance)
      services.tlp.settings = {
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";
      };

      # Readable console on the 4K panel (the 7590 module sets earlySetup)
      console = {
        font = "ter-v32n";
        packages = [ pkgs.terminus_font ];
      };

      home-manager.users.erik = {
        imports = with inputs.self.modules.homeManager; [
          gh
          geforcenow
        ];

        # x86_pkg_temp
        systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone12/temp";

        # HM's sway wrapper is the one on PATH, so these go here, not in
        # programs.sway. Sway refuses to start while the nvidia module is
        # loaded; it renders on the iGPU, the 1650 only runs nvidia-offload.
        # Anything that opens the 1650 keeps it awake: wlroots opens every DRM
        # card, and EGL device enumeration loads nvidia's vendor library.
        wayland.windowManager.sway = {
          extraOptions = [ "--unsupported-gpu" ];
          extraSessionCommands = ''
            export WLR_DRM_DEVICES=/dev/dri/igpu
            export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
          '';
        };
      };
    };
}
