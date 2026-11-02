{ inputs, ... }:
{
  flake.modules.nixos.commonDesktop =
    {
      config,
      pkgs,
      pkgsUnstable,
      ...
    }:
    let
      kb = config.systemConstants.keyboard;
      isLaptop = config.systemConstants.system.type == "laptop";
    in
    {
      imports = with inputs.self.modules.nixos; [
        commonConfig
        memory
        devTools
      ];

      config = {
        # alacritty comes with the WM stacks (EXWM uses vterm instead)
        home-manager.sharedModules = with inputs.self.modules.homeManager; [
          nmtui
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
          xinit
          fastfetch
          spotify
        ];

        hardware.graphics.enable32Bit = true;

        users.users.erik.extraGroups = [ "video" ];

        programs.ssh.askPassword = "${pkgsUnstable.openssh-askpass}/libexec/gtk-ssh-askpass";
        services.udev.packages = [ pkgs.brightnessctl ];
        # Opens 1714-1764 on every interface; keep it off roaming laptops
        programs.kdeconnect.enable = !isLaptop;
        programs.dconf.enable = true;
        services.gnome.gnome-keyring.enable = true;
        security.rtkit.enable = true;
        services.pipewire.enable = false;
        services.flatpak.enable = true;
        services.fwupd.enable = true;
        services.speechd.enable = false;

        services.printing.enable = true;
        # Network printer discovery for CUPS
        services.avahi = {
          enable = true;
          nssmdns4 = true;
        };

        # Thunar mounts and trash need gvfs + udisks2; tumbler for thumbnails
        programs.thunar.enable = true;
        services.gvfs.enable = true;
        services.udisks2.enable = true;
        services.tumbler.enable = true;

        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          # Pre-1.17 behaviour (first portal found); sway overrides this via config.sway
          config.common.default = "*";
        };
      };
    };
}
