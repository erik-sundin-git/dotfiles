{ config, lib, ... }:
let
  # A host whose aspect name doesn't match gets nothing applied (den makes an
  # empty aspect for it) and fails much later with "boot loader not
  # configured". Every host file sets systemConstants.system.host, so a host
  # whose config lacks its own name got none of its file.
  noAspect = lib.filter (
    h: (config.flake.nixosConfigurations.${h}.config.systemConstants.system.host or null) != h
  ) (lib.attrNames config.den.hosts.x86_64-linux);
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.den-aspects =
        if noAspect != [ ] then
          throw "den hosts whose den.aspects.<host> name matches no host file: ${toString noAspect}"
        else
          pkgs.emptyFile;
    };

  # system.stateVersion lives in each host file: it records the release a host
  # was installed with, so it must never change for an existing host.
  den.hosts.x86_64-linux.nomad = { };
  den.hosts.x86_64-linux.ether = { };
  den.hosts.x86_64-linux.specter = { };
  den.hosts.x86_64-linux.wisp = { };
  den.hosts.x86_64-linux.xps = { };
  # install-host inserts new hosts above this line
}
