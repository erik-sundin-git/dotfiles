{ ... }:
{
  # `ssh <host>` for every entry in the LAN inventory (nix/secrets/hosts.nix)
  flake.modules.homeManager.ssh =
    { config, lib, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = lib.mapAttrs (_: h: {
          HostName = h.ip;
          User = h.user;
        }) config.systemConstants.network.hosts;
      };
    };
}
