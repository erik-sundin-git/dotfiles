{ inputs, ... }:
{
  flake.modules.nixos.commonDesktop =
    { config, pkgs, pkgsUnstable, ... }:
    let
      kb = config.systemConstants.keyboard;
    in
    {
      imports = [ inputs.self.modules.nixos.commonConfig ];
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
    };
}
