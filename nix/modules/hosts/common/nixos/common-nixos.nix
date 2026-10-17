{ inputs, ... }:
{
  flake.modules.nixos.commonConfig =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
        nixpkgs.config.allowUnfree = true;
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
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
        nix.settings.warn-dirty = false;
        nix.settings.trusted-users = [
          "root"
          "erik"
        ];
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
          };
        };
        users.users.erik.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINLYub6F3p047lqIQgzoygdVEnohBMdrJe75tYx/ZuCT erik@nomad"
        ];
        services.tlp = {
          enable = lib.mkDefault (config.systemConstants.system.type == "laptop");
          settings = {
            # Keep TLP's USB autosuspend away from the bluetooth adapter
            USB_EXCLUDE_BTUSB = 1;
          };
        };
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        boot.loader.systemd-boot.enable = lib.mkIf config.commonConfig.bootEFI true;
        boot.loader.efi.canTouchEfiVariables = lib.mkIf config.commonConfig.bootEFI true;

        environment.systemPackages = with pkgs; [
          python3
          gnumake
          unzip
          wget
          clang-tools
          git-crypt
          sops
          ssh-to-age
          age
        ];
      };
    };
}
