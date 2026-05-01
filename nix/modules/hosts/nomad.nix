{ den, inputs, ... }:
{
  den.aspects.nomad = {
    homeManager =
      { pkgs, ... }:
      {
        imports = with inputs.self.modules.homeManager; [
          debianMinimal
          minimalConfig
          i3Stack
          alacritty
          vpn
        ];
        home.packages = with pkgs; [ protonmail-desktop ];
        debianGL.nixGLPackage = inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel;
        systemConstants.system.type = "laptop";
        systemConstants.system.host = "nomad";
        systemConstants.latitude = 59.33;
        systemConstants.longitude = 18.07;
        systemConstants.thermalZonePath = "/sys/class/thermal/thermal_zone6/temp";
      };
  };
}
