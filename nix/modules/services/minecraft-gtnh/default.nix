{ ... }:
{
  flake.modules.nixos.gtnh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.gtnh;

      startScript = pkgs.writeShellScript "start-gtnh" ''
        set -euo pipefail
        cd ${cfg.dataDir}
        exec ${cfg.javaPackage}/bin/java \
          -Xmx${cfg.maxRam} -Xms${cfg.minRam} \
          @${cfg.dataDir}/java9args.txt \
          -jar ${cfg.dataDir}/lwjgl3ify-forgePatches.jar nogui
      '';
    in
    {
      options.services.gtnh = {
        enable = lib.mkEnableOption "GT: New Horizons Minecraft server";

        dataDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/gtnh";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "minecraft";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "minecraft";
        };

        javaPackage = lib.mkOption {
          type = lib.types.package;
          default = pkgs.jdk21;
        };

        maxRam = lib.mkOption {
          type = lib.types.str;
          default = "6G";
        };

        minRam = lib.mkOption {
          type = lib.types.str;
          default = "1G";
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        users.users.${cfg.user} = {
          isSystemUser = true;
          group = cfg.group;
          home = cfg.dataDir;
          createHome = true;
        };

        users.groups.${cfg.group} = { };

        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 25565 ];
        networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ 25565 ];

        boot.kernel.sysctl."vm.max_map_count" = 2147483642;

        systemd.services.gtnh = {
          description = "GT: New Horizons Minecraft Server";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            WorkingDirectory = cfg.dataDir;
            ExecStart = "${startScript}";
            Restart = "on-failure";
            RestartSec = "10s";
            TimeoutStopSec = "60";
            PrivateTmp = true;
            ProtectSystem = "strict";
            ReadWritePaths = [ cfg.dataDir ];
          };
        };
      };
    };
}
