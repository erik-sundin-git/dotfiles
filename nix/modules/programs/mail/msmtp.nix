{ ... }:
{
  flake.modules.homeManager.mail =
    { ... }:
    {
      # Sends through Bridge SMTP; Emacs calls it as sendmail (mail-emacs.nix).
      # Bridge files sent mail in Sent itself, so nothing is saved locally.
      programs.msmtp.enable = true;
      accounts.email.accounts.proton.msmtp.enable = true;
    };
}
