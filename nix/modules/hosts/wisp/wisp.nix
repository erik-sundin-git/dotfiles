{ den, inputs, ... }:
{
  den.aspects.wisp = {
    nixos =
      { ... }:
      {
        imports = with inputs.self.modules.nixos; [
          serverProfile
          gtnh
        ];

        systemConstants.system.host = "wisp";

        services.gtnh = {
          enable = true;
          maxRam = "6G";
          minRam = "1G";
          openFirewall = true;
        };
      };
  };
}
