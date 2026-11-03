# Stand-in for nix/secrets/mail.nix in CI, where the repo stays git-crypt
# locked. Same shape; addresses use RFC 2606's reserved domain.
{
  aliases = [ "alias@example.org" ];
}
