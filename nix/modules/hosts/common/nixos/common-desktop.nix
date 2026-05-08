{ inputs, ... }:
{
  flake.modules.nixos.commonDesktop =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.commonConfig ];
      services.xserver.enable = true;
      services.xserver.xkb = {
        layout = "se";
        variant = "";
        options = "ctrl:swapcaps";
      };

      environment.systemPackages = with pkgs; [
        claude-code
        xorg.xinit
        ssh-askpass-fullscreen
      ];

      users.users.erik = {
        isNormalUser = true;
        description = "erik";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };

      nixpkgs.overlays = [ inputs.nur.overlays.default ];
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
}
