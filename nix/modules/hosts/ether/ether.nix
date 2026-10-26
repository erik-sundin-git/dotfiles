{ den, inputs, ... }:
{
  den.aspects.ether = {
    nixos =
      { ... }:
      {
        imports = with inputs.self.modules.nixos; [ vmProfile ];

        systemConstants.system.host = "ether";

        commonConfig.bootEFI = false;
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/vda";
        boot.loader.grub.useOSProber = true;
      };
  };
}
