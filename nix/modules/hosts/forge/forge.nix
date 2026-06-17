{ den, inputs, ... }:
{
  den.aspects.forge = {
    nixos =
      { ... }:
      let
        sysConst = {
          type = "desktop";
          host = "forge";
        };
      in
      {
        imports = with inputs.self.modules.nixos; [
          inputs.home-manager.nixosModules.home-manager
          commonDesktop
          i3Stack
          pulseaudio
          virtManager
        ];

        systemConstants.system = sysConst;

        home-manager.users.erik = {
          imports = [ inputs.self.modules.homeManager.gh ];
          systemConstants.system = sysConst;
          systemConstants.thermalZonePath = "/sys/class/hwmon/hwmon2/temp1_input";

          programs.autorandr = {
            enable = true;
            profiles.forge = {
              fingerprint = {
                DP-1 = "00ffffffffffff001e6d6877158e060007210104b5502178fd9c65a6534d9f250f5054210800d1c0614001010101010101010101010148d570b0d0a0465030203a00204e3100001a000000fd0030a0fafa5a010a202020202020000000fc004c4720554c545241574944450a000000ff003330374e545a4e434d3538390a020b02032e7223090707453f1004030183010000e305c000e2006ae606050153532e6d1a0000020530a00004532e532e7d7d70b0d0a0295030203a00204e3100001a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009d7012790000030128c43901066f0daf002f801f009f05660002000900045901866f0daf002f801f009f055600020009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005590";
                HDMI-1 = "00ffffffffffff0010ac2f424c4e4c4212200103803c2278eeee95a3544c99260f5054a54b00714f8180a940d1c00101010101010101565e00a0a0a029503020350055502100001a000000ff00334a59544348330a2020202020000000fc0044454c4c205532373232440a20000000fd00314c1e5a19000a2020202020200126020324f14f90050403020716010611121513141f23097f078301000067030c001000383c023a801871382d40582c450055502100001e7e3900a080381f4030203a0055502100001a011d007251d01e206e28550055502100001ebf1600a08038134030203a0055502100001a0000000000000000000000000000000000000010";
              };
              config = {
                DP-2.enable = false;
                DP-1 = {
                  enable = true;
                  primary = true;
                  mode = "3440x1440";
                  position = "0x0";
                  rate = "159.96";
                };
                HDMI-1 = {
                  enable = true;
                  mode = "2560x1440";
                  position = "3440x0";
                  rate = "59.95";
                };
              };
            };
          };
        };
      };
  };
}
