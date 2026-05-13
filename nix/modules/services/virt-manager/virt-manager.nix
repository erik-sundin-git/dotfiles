{ ... }:
{
  flake.modules.nixos.virtManager =
    { pkgs, ... }:
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
        };
      };

      virtualisation.spiceUSBRedirection.enable = true;

      programs.virt-manager.enable = true;

      users.users.erik.extraGroups = [ "libvirtd" ];
    };
}
