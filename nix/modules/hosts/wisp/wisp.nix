{ den, inputs, ... }:
{
  den.aspects.wisp = {
    nixos =
      { ... }:
      let
        sysConst = {
          type = "server";
          host = "wisp";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          commonConfig
          gtnh
        ];

        systemConstants.system = sysConst;

        services.gtnh = {
          enable = true;
          maxRam = "6G";
          minRam = "1G";
          openFirewall = true;
        };

        services.logind.settings.Login.HandleLidSwitch = "ignore";
        services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

        systemd.sleep.extraConfig = ''
          AllowSuspend=no
          AllowHibernation=no
          AllowSuspendThenHibernate=no
        '';

        programs.ssh.askPassword = "";

        nixpkgs.overlays = [
          inputs.self.overlays.default
          inputs.nur.overlays.default
        ];

        users.users.erik = {
          isNormalUser = true;
          description = "erik";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
        };

        home-manager.backupFileExtension = "backup";
        home-manager.sharedModules = with inputs.self.modules.homeManager; [ commonHome ];
        home-manager.users.erik = { ... }: {
          systemConstants.system = sysConst;
        };
      };
  };
}
