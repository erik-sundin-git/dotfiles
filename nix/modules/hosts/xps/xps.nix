{ inputs, ... }:
{
  den.aspects.xps.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = with inputs.self.modules.nixos; [
        inputs.nixos-hardware.nixosModules.dell-xps-15-7590-nvidia
        laptopBaseProfile
        swayfxStack
        gaming
        intelGen9Graphics
      ];

      systemConstants.system.host = "xps";
      system.stateVersion = "26.05";

      # Keep the display and session awake while docked or charging. The
      # session idle commands also check AC state before blanking or sleeping.
      services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

      services.hardware.bolt.enable = true;

      # Reachable over ssh, unlike the other laptops (commonConfig closes 22)
      services.openssh.openFirewall = true;
      services.openssh.settings.PasswordAuthentication = lib.mkForce true;

      # Stable name for the iGPU: cardN changes between boots, and the by-path
      # names contain ':', the WLR_DRM_DEVICES separator.
      # ntsync: see boot.kernelModules below.
      services.udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
        KERNEL=="ntsync", TAG+="uaccess"
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

      # 615's GLX module segfaults Xorg on load, and LightDM's greeter is an
      # Xorg server, so with LightDM the machine boots to no login screen.
      # greetd + tuigreet log in on the console and start sway with no X.
      # Switching display managers kills the running session: apply with
      # `rebuild boot` (nh os boot) and reboot, not switch.
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;
      services.greetd = {
        enable = true;
        settings.default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd sway";
      };
      security.pam.services.greetd.enableGnomeKeyring = true;

      # nixpkgs defaults to nvidia's new kernel suspend notifiers with 595 +
      # open modules; the first suspend with them never came back. Use the
      # nvidia-suspend/resume systemd services instead.
      hardware.nvidia.powerManagement.kernelSuspendNotifier = false;

      # GE-Proton sets WINENTSYNC=1 but falls back to fsync (wineserver
      # burning CPU) when /dev/ntsync is missing. The module isn't autoloaded,
      # and the node is root-only without a rule; the uaccess rule in
      # services.udev.extraRules above gives it to the seat user.
      boot.kernelModules = [ "ntsync" ];

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
          dellU2722d
          chromium
          emacsYoutube
        ];

        selectedTheme = "ef-bio";
        # x86_pkg_temp
        systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone12/temp";
        services.poweralertd.enable = false;

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
