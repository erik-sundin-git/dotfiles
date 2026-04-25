{ den, inputs, ... }:
{
  den.aspects.ether = {
    nixos =
      { config, pkgs, ... }:
      let
        sysConst = {
          type = "desktop";
          host = "ether";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          xfce
          commonConfig
        ];

        nixpkgs.overlays = [ inputs.nur.overlays.default ];

        environment.systemPackages = with pkgs; [
          claude-code
          xorg.xinit
          ssh-askpass-fullscreen
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = [ inputs.self.modules.homeManager.minimal-config ];
          systemConstants.system = sysConst;
        };

        users.users.erik = {
          isNormalUser = true;
          description = "erik";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
        };

        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/vda";
        boot.loader.grub.useOSProber = true;

        services.xserver.enable = true;
        services.xserver.xkb = {
          layout = "se";
          variant = "";
          options = "ctrl:swapcaps";
        };

        services.printing.enable = true;
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

      };
  };
}
