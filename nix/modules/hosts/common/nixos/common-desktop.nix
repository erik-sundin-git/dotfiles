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
        openssh-askpass
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
        ];
      };

      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nur.overlays.default
        inputs.emacs-overlay.overlays.default
      ];
      programs.ssh.askPassword = "${pkgs.openssh-askpass}/libexec/gtk-ssh-askpass";
      programs.dconf.enable = true;
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
