{ den, inputs, ... }:
{
  den.aspects.forge = {
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
        systemConstants.system.type = "desktop";
        systemConstants.system.host = "forge";
      };
  };
}
