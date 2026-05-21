{ inputs, ... }:
{
  flake.modules.nixos.commonConfig =
    { config, lib, pkgs, ... }:
    {
      imports = [
        inputs.self.modules.generic.systemConstants
      ];
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
      nix.settings.trusted-users = [ "root" "erik" ];
      services.openssh.enable = true;
      services.tlp = {
        enable = lib.mkDefault (config.systemConstants.system.type == "laptop");
        settings = {
          START_CHARGE_THRESH_BAT0 = 0;
          STOP_CHARGE_THRESH_BAT0 = 100;
          # Prevent TLP from powering off bluetooth
          BLUETOOTH_IDLE_SUSPEND = 0;
        };
      };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      environment.systemPackages = [ pkgs.python3 ];
    };
}
