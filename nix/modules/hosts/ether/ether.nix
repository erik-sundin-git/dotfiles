{ inputs, ... }:
{
  den.aspects.ether = {
    nixos =
      { ... }:
      {
        imports = with inputs.self.modules.nixos; [ vmProfile ];

        systemConstants.system.host = "ether";
        system.stateVersion = "25.11";

        commonConfig.bootEFI = false;
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/vda";
      };
  };
}
