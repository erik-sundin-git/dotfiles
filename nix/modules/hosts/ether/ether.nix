{ den, inputs, ... }:
{
  den.aspects.ether = {
    nixos =
      { config, pkgs, ... }:
      {
        imports = [
          inputs.home-manager.nixosModules.home-manager
          inputs.self.modules.nixos.xfce
        ];
        nixpkgs.overlays = [ inputs.nur.overlays.default ];
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = with pkgs; [
          nixfmt
          claude-code
          xorg.xinit
          tmux
          cmake
          ssh-askpass-fullscreen
        ];
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.erik = {
          imports = [ inputs.self.modules.homeManager.minimal-config ];
          systemConstants.system.type = "desktop";
          systemConstants.system.host = "ether";
        };
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/vda";
        boot.loader.grub.useOSProber = true;
        networking.hostName = "nixos";
        networking.networkmanager.enable = true;
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
        services.xserver.enable = true;
        services.xserver.xkb = {
          layout = "se";
          variant = "";
          options = "ctrl:swapcaps";
        };
        console.keyMap = "sv-latin1";
        services.printing.enable = true;
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
        users.users.erik = {
          isNormalUser = true;
          description = "erik";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
        };
        programs.firefox.enable = true;
        services.openssh.enable = true;
      };
  };
}
