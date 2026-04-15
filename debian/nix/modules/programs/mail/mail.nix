{ inputs, ... }:
{
  flake.modules.homeManager.mail =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.libnotify ];

      systemd.user.services.protonmail-bridge = {
        Unit = {
          Description = "ProtonMail Bridge";
          After = [ "network.target" ];
          Wants = [ "network.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "/usr/bin/protonmail-bridge --cli";
          Restart = "on-failure";
          RestartSec = "10s";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.services.mbsync = {
        Unit = {
          Description = "Sync mail with mbsync and index with notmuch";
          After = [ "network.target" "protonmail-bridge.service" ];
          Wants = [ "protonmail-bridge.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStartPre = [
            # Poll until bridge IMAP port is ready (up to 30s)
            "/bin/bash -c 'for i in $(seq 1 30); do (echo > /dev/tcp/127.0.0.1/1143) 2>/dev/null && exit 0; sleep 1; done; exit 1'"
            "-${pkgs.libnotify}/bin/notify-send 'Mail' 'Fetching mail...' --icon=mail-unread"
          ];
          ExecStart = "/usr/bin/mbsync proton";
          ExecStartPost = [
            "/usr/bin/notmuch new"
            "-${pkgs.libnotify}/bin/notify-send 'Mail' 'Mail synced' --icon=mail-message"
          ];
        };
      };

      systemd.user.timers.mbsync = {
        Unit = {
          Description = "Run mbsync every 5 minutes";
        };
        Timer = {
          OnBootSec = "3min";
          OnUnitActiveSec = "5min";
          AccuracySec = "1min";
          Persistent = true;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
}
