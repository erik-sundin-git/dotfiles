{ ... }:
{
  # system.stateVersion lives in each host file: it records the release a host
  # was installed with, so it must never change for an existing host.
  den.hosts.x86_64-linux.nomad = { };
  den.hosts.x86_64-linux.ether = { };
  den.hosts.x86_64-linux.specter = { };
  den.hosts.x86_64-linux.wisp = { };
  den.hosts.x86_64-linux.xps = { };
  # install-host inserts new hosts above this line
}
