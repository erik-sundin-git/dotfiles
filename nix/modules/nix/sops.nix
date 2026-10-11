{ inputs, ... }:
{
  # Runtime secrets, decrypted at activation with the host's SSH key.
  # Inactive until nix/secrets/secrets.yaml exists (create it with `sops` from nix/secrets/).
  flake.modules.nixos.sops =
    { lib, ... }:
    let
      secretsFile = "${inputs.self}/nix/secrets/secrets.yaml";
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      config = lib.mkIf (builtins.pathExists secretsFile) {
        sops.defaultSopsFile = secretsFile;
        sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };
    };
}
