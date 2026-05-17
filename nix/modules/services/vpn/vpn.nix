{ inputs, ... }:
{
  flake.modules.homeManager.vpn =
    { pkgs, ... }:
    let
      pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages =
        (with pkgs; [
          wireguard-tools
        ])
        ++ [
          pkgsUnstable.proton-vpn-cli
        ]
        ++ [
          (pkgs.writeShellApplication {
            name = "vpn-status";
            text = builtins.readFile ./vpn-status.sh;
          })
        ];

      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" ];
      };
    };
}
