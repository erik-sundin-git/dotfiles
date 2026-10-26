{ inputs, ... }:
{
  # `install-host`: reinstall an existing host or scaffold a new one from a
  # type profile (see hosts/common/nixos/profiles.nix), then nixos-install it.
  flake.modules.nixos.installHost =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "install-host";
          runtimeInputs = with pkgs; [
            parted
            util-linux
            e2fsprogs
            dosfstools
            git
            git-crypt
            systemd
            gnugrep
            gnused
            coreutils
          ];
          text = builtins.readFile "${inputs.self}/nix/assets/install-host.sh";
        })
      ];
    };
}
