{ inputs, ... }:
{
  flake.modules.homeManager.debianMinimal =
    { pkgs, lib, config, ... }:
    let
      nixGLPkg = config.debianGL.nixGLPackage;
      wrapGL =
        bin: pkg:
        if nixGLPkg == null then
          pkg
        else
          pkgs.writeShellScriptBin bin ''exec ${lib.getExe nixGLPkg} ${pkg}/bin/${bin} "$@"'';
    in
    {
      options.debianGL.nixGLPackage = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
      };

      config = {
        nixpkgs.overlays = [ inputs.nur.overlays.default ];
        nixpkgs.config.allowUnfree = true;
        nix.package = pkgs.nix;
        home.packages = [
          pkgs.nixfmt
          (wrapGL "kitty" pkgs.kitty)
        ];
        home.homeDirectory = "/home/erik";
      };
    };
}
