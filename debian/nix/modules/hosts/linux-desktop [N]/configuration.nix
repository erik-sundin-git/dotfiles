{
  inputs,
  ...
}:

{
  flake.modules.nixos.linux-desktop =
    {
      pkgs,
      config,
      ...
    }:
    {
      imports = with inputs.self.modules.nixos; [
        system-desktop
        picom
        i3
      ];

      # Bootloader.
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/nvme0n1";
      boot.loader.grub.useOSProber = true;

      # Kernel and performance
      powerManagement.cpuFreqGovernor = "performance";
      boot.kernelPackages = pkgs.linuxPackages_zen;
    };
}
