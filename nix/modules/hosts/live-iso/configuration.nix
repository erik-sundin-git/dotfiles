{ inputs, ... }:
{
  # Installer session: nomad's sway look (catppuccin, waybar, wofi, alacritty)
  # without the day-to-day apps. The installer's getty autologin of `nixos` on
  # tty1 starts sway from bash, so there is no display manager.
  flake.modules.nixos.liveIsoConfig =
    {
      lib,
      pkgs,
      pkgsUnstable,
      ...
    }:
    {
      imports = with inputs.self.modules; [
        generic.systemConstants # pkgsUnstable
        nixos.swayfx
        nixos.nixDaemon
      ];

      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nur.overlays.default
        inputs.emacs-overlay.overlays.default
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      isoImage.squashfsCompression = "lz4";

      # install-host only creates ext4
      boot.supportedFilesystems.zfs = lib.mkForce false;

      console.keyMap = "sv-latin1";

      # nmtui instead of the installer's wpa_supplicant; `nixos` is already in
      # the networkmanager group
      networking.networkmanager.enable = true;
      networking.wireless.enable = lib.mkImageMediaOverride false;
      hardware.enableRedistributableFirmware = true;

      # Let sway fall back to software rendering in VMs without GL
      environment.sessionVariables.WLR_RENDERER_ALLOW_SOFTWARE = "1";

      environment.systemPackages = [
        pkgs.git
        pkgs.git-crypt
        pkgsUnstable.claude-code
      ];

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.nixos = {
        imports = with inputs.self.modules; [
          generic.systemConstants
          generic.theme
          homeManager.swayfx
          homeManager.waybar
          homeManager.wofi
          homeManager.gtk
          homeManager.dunst
          homeManager.starship
          homeManager.alacritty
          homeManager.nmtui
          homeManager.bash
          homeManager.emacs
          homeManager.mozillaShared
          homeManager.firefox
        ];

        # Normally set by commonHome, which is erik-specific
        _module.args.isLaptop = true;
        systemConstants.system = {
          type = "laptop";
          host = "live-iso";
        };
        selectedTheme = "catppuccin";

        wayland.windowManager.sway.config.startup = lib.mkForce [ { command = "alacritty"; } ];

        # No `exec`: if sway fails to start, drop to a shell instead of
        # looping through getty autologin
        programs.bash.profileExtra = lib.mkForce ''
          if [ -z "''${WAYLAND_DISPLAY}" ] && [ "$(tty)" = "/dev/tty1" ]; then
            sway
          fi
        '';
        programs.bash.initExtra = ''
          echo -e "\033[33mRun install-host to install NixOS (nmtui for wifi).\033[0m"
        '';

        home.username = "nixos";
        home.homeDirectory = "/home/nixos";
        home.stateVersion = "25.11";
      };
    };
}
