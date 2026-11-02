{ ... }:
{
  flake.modules.nixos.virtManager =
    { config, pkgs, ... }:
    let
      images = "/var/lib/libvirt/images";
      # `build-iso` builds the live ISO and drops it into the default pool under
      # a fixed name, so a VM's CD-ROM keeps pointing at the latest build
      buildIso = pkgs.writeShellApplication {
        name = "build-iso";
        runtimeInputs = [ config.virtualisation.libvirtd.package ];
        text = ''
          iso=$(nix build "$HOME/dotfiles#iso" --no-link --print-out-paths)
          src=$(echo "$iso"/iso/*.iso)
          # copy then rename, so a running VM keeps reading the old file
          sudo install -m 0644 "$src" ${images}/.nixos-live.iso.tmp
          sudo mv -f ${images}/.nixos-live.iso.tmp ${images}/nixos-live.iso
          virsh -c qemu:///system pool-refresh default >/dev/null
          echo "${images}/nixos-live.iso ($(basename "$src"))"
        '';
      };
    in
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
      environment.systemPackages = [
        pkgs.quickemu
        buildIso
      ];

      users.users.erik.extraGroups = [ "libvirtd" ];
    };
}
