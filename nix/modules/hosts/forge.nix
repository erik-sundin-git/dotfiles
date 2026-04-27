{ den, inputs, ... }:
{
  den.aspects.forge = {
    homeManager =
      { pkgs, ... }:
      {
        imports = with inputs.self.modules.homeManager; [
          debianMinimal
          minimalConfig
          i3
          alacritty
        ];
        debianGL.nixGLPackage = inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLNvidia;
        systemConstants.system.type = "desktop";
        systemConstants.system.host = "forge";
      };
  };
}
