{ inputs, ... }:
{
  den.aspects.wisp = {
    nixos =
      { ... }:
      {
        imports = with inputs.self.modules.nixos; [ serverProfile ];

        systemConstants.system.host = "wisp";
        system.stateVersion = "25.11";
      };
  };
}
