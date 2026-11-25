# The GTX 1650: PRIME offload only. Sway and everything else run on the iGPU,
# since anything that opens the 1650 keeps it awake.
{ ... }:
{
  den.aspects.xps.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Stable name for the iGPU: cardN changes between boots, and the by-path
      # names contain ':', the WLR_DRM_DEVICES separator.
      services.udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
      '';

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

          # Battle.net on the 1650. prev is gaming's unstable umu-launcher.
          umu-launcher = final.symlinkJoin {
            name = "umu-launcher-nvidia-offload";
            paths = [ prev.umu-launcher ];
            postBuild = ''
              rm $out/bin/umu-run
              cat >$out/bin/umu-run <<EOF
              #!${final.runtimeShell}
              exec ${final.nvidia-offload}/bin/nvidia-offload ${prev.umu-launcher}/bin/umu-run "\$@"
              EOF
              chmod +x $out/bin/umu-run
            '';
          };

          # Minecraft (GTNH) on the 1650.
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

      # NVIDIA 615 (nixpkgs-unstable's `latest`; stable tops out at 595.71.05,
      # which doesn't build on gaming's linuxPackages_latest). mkDriver is
      # stable's builder, so the module is built against this host's kernel;
      # hashes copied from unstable's pkgs/os-specific/linux/nvidia-x11/default.nix.
      # Drop this once stable's `latest` reaches 615.
      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "615.78.08";
        sha256_64bit = "sha256-Pj9t3cLudnoIGFMAr3vjyyhuznZpjS3eNSRZl4LQf/4=";
        sha256_aarch64 = "sha256-UHYBE1AYHoGgMfD9AS/jX+S+N8eCDWUft6qolK9Eejc=";
        openSha256 = "sha256-HBINiOjL0ZJLIAJeNIBYHBnwgUXtNwPPtnFpAI1YwF4=";
        settingsSha256 = "sha256-inDRpG02sdDgHmlqgu/DsgK8OFdOt1fZIYyXdhlGC/c=";
        persistencedSha256 = "sha256-RzeR6Ldct6MUxjnXRyThdh5Y3jjMehTVg85MtwuWNX4=";
      };

      # nixpkgs defaults to nvidia's new kernel suspend notifiers with 595 +
      # open modules; the first suspend with them never came back. Use the
      # nvidia-suspend/resume systemd services instead.
      hardware.nvidia.powerManagement.kernelSuspendNotifier = false;

      # Steam's Vulkan probing opens the 1650 and keeps it awake for as long
      # as the client runs. Show it only the Intel ICDs; games that want the
      # 1650 use the launch option `nvidia-offload %command%`.
      programs.steam.package = pkgs.steam.override {
        extraEnv.VK_DRIVER_FILES = lib.concatStringsSep ":" [
          "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
          "/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json"
        ];
      };

      # HM's sway wrapper is the one on PATH, so these go here, not in
      # programs.sway. Sway refuses to start while the nvidia module is
      # loaded; it renders on the iGPU, the 1650 only runs nvidia-offload.
      # wlroots opens every DRM card, and EGL device enumeration loads
      # nvidia's vendor library, either of which would wake the 1650.
      home-manager.users.erik.wayland.windowManager.sway = {
        extraOptions = [ "--unsupported-gpu" ];
        extraSessionCommands = ''
          export WLR_DRM_DEVICES=/dev/dri/igpu
          export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
        '';
      };
    };
}
