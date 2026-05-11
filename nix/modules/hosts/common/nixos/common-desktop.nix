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
          "video"
        ];
      };

      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nur.overlays.default
        inputs.emacs-overlay.overlays.default
      ];
      programs.ssh.askPassword = "${pkgs.openssh-askpass}/libexec/gtk-ssh-askpass";
      services.udev.packages = [ pkgs.brightnessctl ];
      programs.dconf.enable = true;
      services.printing.enable = true;
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.extraConfig."10-bluez" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.auto-connect" = [ "hfp_hf" "hsp_hs" "a2dp_sink" ];
          };
        };
      };

      hardware.bluetooth.settings.General.Experimental = true;
    };
}
