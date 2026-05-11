{ inputs, ... }:
{
  flake.modules.homeManager.mail =
    { pkgs, ... }:
    let
      # Poll until ProtonMail Bridge IMAP port (1143) is ready, up to 30 seconds
      waitForBridge = pkgs.writeShellScript "wait-for-bridge" ''
        for i in $(seq 1 30); do
          (echo > /dev/tcp/127.0.0.1/1143) 2>/dev/null && exit 0
          sleep 1
        done
        exit 1
      '';
    in
    {
      home.packages = with pkgs; [
        libnotify
        protonmail-bridge
        isync
        notmuch
      ];

      systemd.user.services.protonmail-bridge = {
        Unit = {
          Description = "ProtonMail Bridge";
          After = [ "network.target" ];
          Wants = [ "network.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --cli";
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
            "${waitForBridge}"
            "-${pkgs.libnotify}/bin/notify-send 'Mail' 'Fetching mail...' --icon=mail-unread"
          ];
          ExecStart = "${pkgs.isync}/bin/mbsync proton";
          ExecStartPost = [
            "${pkgs.notmuch}/bin/notmuch new"
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
