# Stand-in for nix/secrets/hosts.nix in CI, where the repo stays git-crypt
# locked. Same shape; only the keys modules reference by name are needed.
# Addresses are from RFC 5737's documentation range.
{
  hass-vm = {
    ip = "192.0.2.10";
  };
}
