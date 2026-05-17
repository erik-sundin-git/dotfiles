{ inputs, ... }:
{
  flake.modules.nixos.liveIsoConfig =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [ inputs.emacs-overlay.overlays.default ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      isoImage.squashfsCompression = "lz4";

      console.keyMap = "sv-latin1";

      services.xserver.enable = true;
      services.xserver.xkb.layout = "se";
      services.xserver.xkb.options = "ctrl:swapcaps";

      services.xserver.displayManager.gdm.enable = true;
      services.xserver.displayManager.gdm.wayland = true;
      services.xserver.desktopManager.gnome.enable = true;

      services.displayManager.autoLogin.enable = true;
      services.displayManager.autoLogin.user = "nixos";

      environment.etc."dotfiles".source = inputs.self;

      environment.systemPackages = [
        pkgs.git
        pkgs.claude-code
        inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
      ];

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.nixos = {
        imports = [ inputs.self.modules.homeManager.emacs ];
        home.username = "nixos";
        home.homeDirectory = "/home/nixos";
        home.stateVersion = "25.11";
      };
    };
}
