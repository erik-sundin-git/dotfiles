{ inputs, ... }:
{
  flake.modules.homeManager.mail =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      stage = config.mailSync.stage;
      notmuch = config.programs.notmuch.package;

      mailMove = pkgs.writeShellApplication {
        name = "mail-move";
        runtimeInputs = [
          notmuch
          pkgs.coreutils
          pkgs.gnused
        ];
        text = builtins.readFile "${inputs.self}/nix/assets/mail/mail-move.sh";
      };

      # Exit 1 = skip the run (not a failure) while Bridge is stopped, during
      # its login, or offline (it closes its listeners without a connection).
      syncCondition = pkgs.writeShellScript "mail-sync-condition" ''
        ${pkgs.systemd}/bin/systemctl --user is-active --quiet protonmail-bridge.service || exit 1
        for _ in {1..60}; do
          (exec 3<>/dev/tcp/127.0.0.1/1143) 2>/dev/null && exit 0
          ${pkgs.coreutils}/bin/sleep 1
        done
        exit 1
      '';

      moveCmd = "${mailMove}/bin/mail-move" + lib.optionalString (stage >= 5) " --spam";

      notifySend = "${pkgs.libnotify}/bin/notify-send";

      # Runs in postNew while the new mail still has tag:new. One notification
      # per sync: up to 5 "author; subject" lines, or just the count (first sync).
      notifyNew = ''
        n=$(notmuch count 'tag:arrived and tag:unread')
        if [ "$n" -gt 0 ]; then
          if [ "$n" -le 5 ]; then
            body=$(notmuch search --sort=newest-first 'tag:arrived and tag:unread' \
              | ${pkgs.gnused}/bin/sed -E 's/^thread:[0-9a-f]+ +[^[]*\[[^]]*\] //; s/ \([^()]*\)$//')
          else
            body="$n new messages"
          fi
          ${notifySend} -a mail -i mail-unread "New mail ($n)" "$body" || true
        fi
      '';

      # A broken login or keyring would fail every 5 minutes; notify at most hourly.
      notifyFailed = pkgs.writeShellScript "mail-sync-failed" ''
        stamp=$XDG_RUNTIME_DIR/mail-sync-failed
        if [ -z "$(${pkgs.findutils}/bin/find "$stamp" -mmin -60 2>/dev/null)" ]; then
          ${pkgs.coreutils}/bin/touch "$stamp"
          ${notifySend} -u critical -a mail 'Mail sync failed' 'journalctl --user -u mail-sync'
        fi
      '';
    in
    {
      home.packages = [ mailMove ];

      accounts.email.accounts.proton.notmuch.enable = true;

      # The whole pipeline is `notmuch new`: preNew moves files for changed
      # tags (from stage 3) and runs mbsync, notmuch indexes, postNew tags.
      # Hook PATH holds only notmuch, so everything else uses store paths.
      programs.notmuch = {
        enable = true;
        new.tags = [ "new" ];
        new.ignore = [
          # [.] not \.: the config is a GLib key file, which rejects \. as an escape
          "/[.]mbsyncstate/"
          "/^[.]tags-/"
          ".no-move"
        ];
        search.excludeTags = [
          "deleted"
          "spam"
        ];
        # unread/flagged/replied/draft <-> maildir flags, which mbsync syncs.
        maildir.synchronizeFlags = true;
        hooks.preNew = ''
          set -e
          # Database revision before this sync: postNew treats every message
          # changed since then as just arrived, which also catches a new copy
          # of a known message (self-sent mail: Sent first, then INBOX).
          notmuch count --lastmod '*' | ${pkgs.coreutils}/bin/cut -f3 > "$HOME/Mail/.notmuch/last-rev"
          ${lib.optionalString (stage >= 3) moveCmd}
          ${config.programs.mbsync.package}/bin/mbsync proton
        '';
        # Folders on Proton decide the tags. Local deletes and spam are only
        # reverted once mail-move would carry them out (stage 3 / 5); before
        # that they stay local.
        hooks.postNew = ''
          rev=$(${pkgs.coreutils}/bin/cat "$HOME/Mail/.notmuch/last-rev" 2>/dev/null || true)
          since=tag:new
          if [ -n "$rev" ]; then since="tag:new or lastmod:$((rev + 1)).."; fi
          # tag:arrived marks mail that came into INBOX in this sync (for the
          # notification); it is removed again below.
          notmuch tag --batch <<EOF
          +arrived -- ($since) and folder:"proton/INBOX" and not tag:inbox
          +inbox -- tag:arrived
          +sent -- folder:"proton/Sent" and not tag:sent
          +spam -inbox -- folder:"proton/Spam" and not tag:spam
          +deleted -inbox -- folder:"proton/Trash" and not tag:deleted
          -inbox -- tag:inbox and not tag:new and path:proton/** and not folder:"proton/INBOX"
          ${lib.optionalString (
            stage >= 3
          ) ''-deleted -- tag:deleted and path:proton/** and not folder:"proton/Trash"''}
          ${lib.optionalString (
            stage >= 5
          ) ''-spam -- tag:spam and path:proton/** and not folder:"proton/Spam"''}
          EOF

          ${notifyNew}
          notmuch tag -new -arrived -- tag:new or tag:arrived

          # Daily tag backup (custom tags live only here), kept for 14 days.
          dump=$HOME/Mail/.tags-$(${pkgs.coreutils}/bin/date +%F).gz
          notmuch dump --gzip --output="$dump.tmp" && ${pkgs.coreutils}/bin/mv "$dump.tmp" "$dump"
          ${pkgs.findutils}/bin/find "$HOME/Mail" -maxdepth 1 -name '.tags-*.gz' -mtime +14 -delete
        '';
      };

      systemd.user.services.mail-sync = {
        Unit = {
          Description = "Sync Proton mail (mail-move, mbsync) and index it (notmuch)";
          # No Wants=: the timer must not start Bridge, e.g. during its CLI login.
          After = [ "protonmail-bridge.service" ];
          OnFailure = [ "mail-sync-failed.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecCondition = "${syncCondition}";
          # One run at a time, also against `notmuch new` started elsewhere.
          ExecStart = "${pkgs.util-linux}/bin/flock -n -E 0 %t/mail-sync.lock ${notmuch}/bin/notmuch new";
        };
      };
      systemd.user.services.mail-sync-failed = {
        Unit.Description = "Notify that the mail sync failed";
        Service = {
          Type = "oneshot";
          ExecStart = "${notifyFailed}";
        };
      };

      systemd.user.timers.mail-sync = {
        Unit.Description = "Sync Proton mail every 5 minutes";
        Timer.OnCalendar = "*:0/5";
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
