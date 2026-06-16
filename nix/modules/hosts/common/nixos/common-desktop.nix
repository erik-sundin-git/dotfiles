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
      cfg = config.commonDesktop;
    in
    {
      imports = [ inputs.self.modules.nixos.commonConfig ];

      options.commonDesktop.bootEFI = lib.mkEnableOption "systemd-boot EFI bootloader" // {
        default = true;
      };

      config = {
        boot.loader.systemd-boot.enable = lib.mkIf cfg.bootEFI true;
        boot.loader.efi.canTouchEfiVariables = lib.mkIf cfg.bootEFI true;

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
          claude-code
          xorg.xinit
          pkgsUnstable.openssh-askpass
          quickemu
          cmake
          alacritty
          nixfmt
          fastfetch
          wineWow64Packages.stable
          winetricks
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
        programs.dconf.enable = true;
        services.gnome.gnome-keyring.enable = true;
        services.printing.enable = true;
        security.rtkit.enable = true;
        services.pipewire.enable = false;
        services.flatpak.enable = true;
      };
    };
}
