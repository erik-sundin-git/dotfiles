{ ... }:
{
  # `ssh <host>` for every entry in the LAN inventory (nix/secrets/hosts.nix)
  flake.modules.homeManager.ssh =
    { config, lib, ... }:
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings =
          lib.mapAttrs (_: h: {
            HostName = h.ip;
            User = h.user;
          }) config.systemConstants.network.hosts
          // {
            # Defaults for every host. The connection sharing means a second
            # ssh to a host reuses the first; anything that must use its own
            # key passes -o ControlPath=none (gtnh-backup does).
            "*" = {
              AddKeysToAgent = "yes";
              ServerAliveInterval = 60;
              ServerAliveCountMax = 3;
              ControlMaster = "auto";
              ControlPath = "~/.ssh/cm-%C";
              ControlPersist = "10m";
            };
          };
      };
    };
}
