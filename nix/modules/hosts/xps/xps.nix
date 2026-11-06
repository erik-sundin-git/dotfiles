{ inputs, ... }:
{
  den.aspects."xps".nixos =
    { lib, pkgs, pkgsUnstable, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        # Base 7590 module (deep sleep, thermald, intel cpu/gpu, ssd) plus the
        # GTX 1650 as a PRIME offload GPU with fine-grained runtime PM
        inputs.nixos-hardware.nixosModules.dell-xps-15-7590-nvidia
        laptopBaseProfile
        swayfxStack
        gaming
        ./_hardware-configuration.nix
      ];

      systemConstants.system.host = "xps";
      system.stateVersion = "26.05";

      services.hardware.bolt.enable = true;

      # Reachable over ssh, unlike the other laptops (commonConfig closes 22)
      services.openssh.openFirewall = lib.mkForce true;

      # Stable name for the iGPU: cardN changes between boots, and the by-path
      # names contain ':', the WLR_DRM_DEVICES separator
      services.udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
      '';

      # The stock nvidia-offload, plus re-enabling nvidia's EGL vendor and
      # Vulkan ICD, which the sway session and Steam hide (see below)
      hardware.nvidia.prime.offload.enableOffloadCmd = lib.mkForce false;
      environment.systemPackages = [ pkgs.nvidia-offload ];

      nixpkgs.overlays = [
        (final: prev: {
          nvidia-offload = final.writeShellScriptBin "nvidia-offload" ''
            unset __EGL_VENDOR_LIBRARY_FILENAMES VK_DRIVER_FILES
            export __NV_PRIME_RENDER_OFFLOAD=1
            export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
            export __GLX_VENDOR_LIBRARY_NAME=nvidia
            export __VK_LAYER_NV_optimus=NVIDIA_only
            exec "$@"
          '';

          # battlenet-umu invokes umu-run directly. Wrap it so Battle.net and
          # games launched through its shared prefix use the GTX 1650 too.
          umu-launcher = final.symlinkJoin {
            name = "umu-launcher-nvidia-offload";
            # nixpkgs stable has umu-launcher 1.4.0, whose SteamRT4 bootstrap
            # can fail digest validation. 1.4.3 fixed the runtime metadata URL.
            paths = [ pkgsUnstable.umu-launcher ];
            postBuild = ''
              rm $out/bin/umu-run
              cat >$out/bin/umu-run <<EOF
              #!${final.runtimeShell}
              exec ${final.nvidia-offload}/bin/nvidia-offload ${pkgsUnstable.umu-launcher}/bin/umu-run "\$@"
              EOF
              chmod +x $out/bin/umu-run
            '';
          };

          # Minecraft (GTNH) on the 1650. Prism passes `--launch` to an
          # already-running launcher, so the whole launcher is offloaded, not
          # just the desktop entries; the 1650 stays awake while Prism is open.
          prismlauncher = final.symlinkJoin {
            name = "prismlauncher-nvidia-offload";
            paths = [ prev.prismlauncher ];
            postBuild = ''
              rm $out/bin/prismlauncher
              cat >$out/bin/prismlauncher <<EOF
              #!${final.runtimeShell}
              exec ${final.nvidia-offload}/bin/nvidia-offload ${prev.prismlauncher}/bin/prismlauncher "\$@"
              EOF
              chmod +x $out/bin/prismlauncher
            '';
          };
        })
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

      # Steam's Vulkan probing opens the 1650 and keeps it awake for as long
      # as the client runs. Show it only the Intel ICDs; games that want the
      # 1650 use the launch option `nvidia-offload %command%`.
      programs.steam.package = pkgs.steam.override {
        extraEnv.VK_DRIVER_FILES = lib.concatStringsSep ":" [
          "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
          "/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json"
        ];
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
        RUNTIME_PM_ON_AC = "auto";
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
          intelVideoDecode
          chromium
          emacsYoutube
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
