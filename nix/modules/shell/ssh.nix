{ ... }:
{
  # `ssh <host>` for every entry in the LAN inventory (nix/secrets/hosts.nix)
  flake.modules.homeManager.ssh =
    { config, lib, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = lib.mapAttrs (_: h: {
          hostname = h.ip;
          inherit (h) user;
        }) config.systemConstants.network.hosts;
      };
    };
}
