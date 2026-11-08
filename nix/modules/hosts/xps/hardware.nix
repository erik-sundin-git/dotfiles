{ ... }:
{
  den.aspects.xps = {
    nixos =
      {
        config,
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ];

        fileSystems."/" = {
          device = "/dev/disk/by-uuid/d9c51bd6-4dd6-4732-9c73-637f43fa5b98";
          fsType = "ext4";
          options = [ "noatime" ];
        };

        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/D0FE-CCEF";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };

        swapDevices = [
          { device = "/dev/disk/by-uuid/07815151-5b59-44a4-90e5-7a2bdf358b24"; }
        ];

        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "ahci"
          "nvme"
          "usbhid"
          "usb_storage"
          "sd_mod"
          "rtsx_pci_sdmmc"
        ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
  };
}
