{ inputs, ... }:
{
  flake.modules.nixos.commonDesktop =
    {
      config,
      lib,
      pkgs,
      pkgsUnstable,
      ...
    }:
    let
      kb = config.systemConstants.keyboard;
    in
    {
      imports = with inputs.self.modules.nixos; [
        commonConfig
        memory
      ];

      config = {
        home-manager.backupFileExtension = "backup";
        home-manager.sharedModules = with inputs.self.modules.homeManager; [
          commonHome
          alacritty
          desktopApps
          vpn
        ];

        services.xserver.enable = true;
        services.xserver.xkb = {
          layout = kb.layout;
          variant = "";
          options = kb.options;
        };

        environment.systemPackages = with pkgs; [
          pkgsUnstable.claude-code
          xorg.xinit
          pkgsUnstable.openssh-askpass
          quickemu
          alacritty
          xfce.thunar
          nixfmt
          fastfetch
          wineWow64Packages.stable
          winetricks
          spotify
        ];

        hardware.graphics.enable32Bit = true;

        users.users.erik = {
          isNormalUser = true;
          description = "erik";
          extraGroups = [
            "networkmanager"
            "wheel"
            "video"
          ];
        };

        nixpkgs.overlays = [
          inputs.self.overlays.default
          inputs.nur.overlays.default
          inputs.emacs-overlay.overlays.default
        ];
        programs.ssh.askPassword = "${pkgsUnstable.openssh-askpass}/libexec/gtk-ssh-askpass";
        services.udev.packages = [ pkgs.brightnessctl ];
        programs.kdeconnect.enable = true;
        programs.dconf.enable = true;
        services.gnome.gnome-keyring.enable = true;
        services.printing.enable = true;
        security.rtkit.enable = true;
        services.pipewire.enable = false;
        services.flatpak.enable = true;
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          # Pre-1.17 behaviour (first portal found); sway overrides this via config.sway
          config.common.default = "*";
        };
      };
    };
}
