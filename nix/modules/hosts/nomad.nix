{ den, inputs, ... }:
{
  den.aspects.nomad = {
    homeManager =
      { pkgs, ... }:
      {
        imports = with inputs.self.modules.homeManager; [
          minimal-config
          i3
        ];
        nixpkgs.overlays = [ inputs.nur.overlays.default ];
        nixpkgs.config.allowUnfree = true;
        nix.package = pkgs.nix;
        home.packages = [ pkgs.nixfmt ];
        home.homeDirectory = "/home/erik";
        systemConstants.system.type = "laptop";
        systemConstants.system.host = "nomad";
        systemConstants.latitude = 59.33;
        systemConstants.longitude = 18.07;
      };
  };
}
