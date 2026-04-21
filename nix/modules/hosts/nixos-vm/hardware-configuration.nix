{ ... }:
{
  flake.modules.nixos.nixosVm =
    {
      config,
      lib,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/42a2b345-b55a-4385-9f57-a10a7665c36d";
        fsType = "ext4";
      };

      swapDevices = [ { device = "/dev/disk/by-uuid/e6a69ceb-94b9-4a77-9e05-cd6dfb65fa32"; } ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
