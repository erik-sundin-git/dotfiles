{ inputs, ... }:
{
  flake.modules.nixos.commonConfig =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.systemConstants.system) type;
      isLaptop = type == "laptop";
      isServer = type == "server";
    in
    {
      imports = [
        inputs.self.modules.generic.systemConstants
        inputs.self.modules.nixos.sops
        inputs.self.modules.nixos.nixDaemon
        inputs.self.modules.nixos.nh
      ];

      options.commonConfig.bootEFI = lib.mkEnableOption "systemd-boot EFI bootloader" // {
        default = true;
      };

      config = {
        networking.networkmanager.enable = true;
        networking.hostName = "${config.systemConstants.system.host}";
        time.timeZone = "Europe/Stockholm";
        i18n.defaultLocale = "en_US.UTF-8";
        i18n.extraLocaleSettings = {
          LC_ADDRESS = "sv_SE.UTF-8";
          LC_IDENTIFICATION = "sv_SE.UTF-8";
          LC_MEASUREMENT = "sv_SE.UTF-8";
          LC_MONETARY = "sv_SE.UTF-8";
          LC_NAME = "sv_SE.UTF-8";
          LC_NUMERIC = "sv_SE.UTF-8";
          LC_PAPER = "sv_SE.UTF-8";
          LC_TELEPHONE = "sv_SE.UTF-8";
          LC_TIME = "sv_SE.UTF-8";
        };
        console.keyMap = "sv-latin1";
        nix.settings.warn-dirty = false;
        # A trusted user can add substituters and import unsigned paths, i.e.
        # is root-equivalent without sudo. Fine on personal machines, not on
        # a server that accepts ssh.
        nix.settings.trusted-users = [ "root" ] ++ lib.optional (!isServer) "erik";
        services.openssh = {
          enable = true;
          # Laptops roam onto untrusted networks and nothing ssh's into them
          openFirewall = lib.mkDefault (!isLaptop);
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
            AllowUsers = [ "erik" ];
          };
        };
        users.users.erik.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLYub6F3p047lqIQgzoygdVEnohBMdrJe75tYx/ZuCT erik@nomad"
        ];
        services.tlp = {
          # Not `mkDefault isLaptop`: false would conflict with nixos-hardware's
          # laptop modules (also mkDefault) on a desktop-type host
          enable = lib.mkIf isLaptop (lib.mkDefault true);
          settings = {
            # Keep TLP's USB autosuspend away from the bluetooth adapter
            USB_EXCLUDE_BTUSB = 1;
          };
        };
        boot.loader.systemd-boot.enable = lib.mkIf config.commonConfig.bootEFI true;
        # The menu editor lets anyone at the keyboard boot with init=/bin/sh
        boot.loader.systemd-boot.editor = false;
        # The ESP is 512M (disk-layout.nix): _latest kernels plus systemd
        # initrds fill it long before nh clean prunes generations
        boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
        boot.loader.efi.canTouchEfiVariables = lib.mkIf config.commonConfig.bootEFI true;
        # Hold Space at boot to get the menu
        boot.loader.timeout = lib.mkIf config.commonConfig.bootEFI (lib.mkDefault 1);
        # Not on BIOS/GRUB hosts: only the scripted initrd finds the resume
        # device from swapDevices there; with systemd it comes from an EFI var
        boot.initrd.systemd.enable = lib.mkIf config.commonConfig.bootEFI (lib.mkDefault true);
        services.journald.extraConfig = "SystemMaxUse=500M";

        # Light hardening that costs nothing on a desktop (no ptrace or
        # lockdown limits: those get in the way of gdb, Wine and anti-cheat)
        security.sudo.execWheelOnly = true;
        boot.kernel.sysctl = {
          "kernel.dmesg_restrict" = 1;
          "net.ipv4.conf.all.accept_redirects" = 0;
          "net.ipv4.conf.default.accept_redirects" = 0;
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;
          "net.ipv6.conf.all.accept_redirects" = 0;
          "net.ipv6.conf.default.accept_redirects" = 0;
        };
        services.dbus.implementation = "broker";

        environment.systemPackages = with pkgs; [
          unzip
          zip
          htop
          wget
          git-crypt
          sops
          ssh-to-age
          age
        ];
      };
    };
}
