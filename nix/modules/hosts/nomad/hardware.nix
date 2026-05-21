{ den, lib, ... }:
{
  den.aspects.nomad = {
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

	  fileSystems."/" =
    { device = "/dev/disk/by-uuid/f346b9b7-bb5d-426d-8707-5040673c7fe5";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2538-F177";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/63cfc2dc-2e4d-41a7-bd7d-d98eb719dd3c"; }
    ];

        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "nvme"
          "usb_storage"
          "sd_mod"
        ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];

        # Required for preservation's inInitrd symlinks
        boot.initrd.systemd.enable = true;

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
  };
}
