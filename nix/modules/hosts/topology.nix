{ den, ... }:
{
  den.hosts.x86_64-linux.nomad = { };
  den.hosts.x86_64-linux.forge = { };
  den.hosts.x86_64-linux.ether = { };
  den.hosts.x86_64-linux.specter = { };
  den.default.nixos.system.stateVersion = "25.11";
}
