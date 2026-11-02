{ inputs, ... }:
{
  # `install-host`: the installer TUI (nix/packages/install-host), with the
  # flake's disko so partitioning matches nixos.diskLayout.
  flake.modules.nixos.installHost =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.local.install-host.override {
          inherit (inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}) disko;
        })

        # The previous bash installer, kept for one ISO cycle as a fallback for
        # reinstalls (its new-host path imports the removed laptopProfile)
        (pkgs.writeShellApplication {
          name = "install-host-legacy";
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
            lvm2
          ];
          text = builtins.readFile "${inputs.self}/nix/assets/install-host.sh";
        })
      ];
    };
}
