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

      environment.etc."dotfiles".source = inputs.self;

      environment.systemPackages = [
        pkgs.git
        pkgs.claude-code
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
