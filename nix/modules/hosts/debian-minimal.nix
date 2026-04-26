{ inputs, ... }:
{
  flake.modules.homeManager.debianMinimal =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ inputs.nur.overlays.default ];
      nixpkgs.config.allowUnfree = true;
      nix.package = pkgs.nix;
      home.packages = [ pkgs.nixfmt ];
      home.homeDirectory = "/home/erik";
    };
}
