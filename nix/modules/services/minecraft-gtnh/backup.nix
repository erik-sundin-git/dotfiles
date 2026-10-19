{ ... }:
{
  # Pulls the GTNH world backups off the VPS. Server Utilities writes a zip to
  # /var/lib/gtnh/backups every 30 min while players are online but keeps only
  # 12, so this keeps a longer history locally.
  #
  # Auth is a dedicated passphrase-less key (~/.ssh/gtnh_backup), pinned on the
  # VPS to read-only rsync of that one folder:
  #   restrict,command="/usr/bin/rrsync -ro /var/lib/gtnh/backups/" ssh-ed25519 …
  flake.modules.homeManager.gtnhBackup =
    { config, pkgs, ... }:
    let
      dest = "${config.home.homeDirectory}/backups/gtnh";
      # Counted back from the newest backup, not from today, so a server
      # nobody played on for months doesn't age out every copy.
      keepAllDays = 2;
      keepDailyDays = 60;

      gtnh-backup = pkgs.writeShellApplication {
        name = "gtnh-backup";
        runtimeInputs = with pkgs; [
          rsync
          openssh
          coreutils
        ];
        text = ''
          dest=${dest}
          mkdir -p "$dest"

          # Zips are immutable once written, so existing ones are skipped
          rsync -t --ignore-existing --partial-dir=.partial \
            --include='*.zip' --exclude='*' \
            -e "ssh -i $HOME/.ssh/gtnh_backup -o IdentitiesOnly=yes -o BatchMode=yes" \
            vps: "$dest/"

          # Keep everything from the last ${toString keepAllDays} days, then the
          # newest zip per day for ${toString keepDailyDays} days
          cd "$dest"
          shopt -s nullglob
          zips=(*.zip)
          [ ''${#zips[@]} -eq 0 ] && exit 0
          mapfile -t zips < <(printf '%s\n' "''${zips[@]}" | sort -r)
          newest=''${zips[0]:0:10}
          keepAllAfter=$(date -d "$newest -${toString keepAllDays} days" +%F)
          keepDailyAfter=$(date -d "$newest -${toString keepDailyDays} days" +%F)
          lastDay=
          for f in "''${zips[@]}"; do
            day=''${f:0:10}
            if [[ $day > $keepAllAfter ]] || [[ $day > $keepDailyAfter && $day != "$lastDay" ]]; then
              lastDay=$day
              continue
            fi
            rm -- "$f"
          done
        '';
      };
    in
    {
      home.packages = [ gtnh-backup ];

      systemd.user.services.gtnh-backup = {
        Unit.Description = "Pull GTNH world backups from the VPS";
        Service = {
          Type = "oneshot";
          ExecStart = "${gtnh-backup}/bin/gtnh-backup";
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };

      # Hourly; Persistent catches up after the laptop was off or asleep
      systemd.user.timers.gtnh-backup = {
        Unit.Description = "Pull GTNH world backups from the VPS hourly";
        Timer = {
          OnCalendar = "hourly";
          Persistent = true;
          RandomizedDelaySec = "5min";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
