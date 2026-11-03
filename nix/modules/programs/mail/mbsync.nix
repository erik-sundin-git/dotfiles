{ ... }:
{
  flake.modules.homeManager.mail =
    { config, lib, ... }:
    let
      stage = config.mailSync.stage;
    in
    {
      # Config only (~/.config/isyncrc). mbsync runs from notmuch's preNew hook
      # (notmuch.nix), never from services.mbsync, so mail-move always runs
      # before it.
      programs.mbsync.enable = true;

      accounts.email.accounts.proton.mbsync = {
        enable = true;
        create = "maildir";
        # A folder deleted on Proton keeps its local copy.
        remove = "none";
        # Before stage 4 only the local side is expunged: mail removed on
        # Proton disappears locally, but nothing local deletes on Proton.
        expunge = if stage >= 4 then "both" else "maildir";
        # All Mail, Starred and Labels/* hold a copy of every message per
        # label; each message also sits in one of the real folders synced here.
        patterns = [
          "*"
          "!All Mail"
          "!Starred"
          "!Labels"
          "!Labels/*"
        ];
        extraConfig.account = {
          AuthMechs = "LOGIN";
          Timeout = 120;
        };
        extraConfig.channel = {
          CopyArrivalDate = "yes";
        }
        # From stage 3 on: mbsync's default, everything both ways.
        // lib.optionalAttrs (stage == 1) { Sync = "Pull"; }
        // lib.optionalAttrs (stage == 2) { Sync = "Pull PushFlags"; };
      };
    };
}
