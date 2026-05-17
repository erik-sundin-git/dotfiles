{ ... }:
{
  flake.modules.homeManager.airstatus =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.services.airstatus = {
        enable = lib.mkEnableOption "AirStatus AirPods battery monitor";
        outputFile = lib.mkOption {
          type = lib.types.str;
          default = "/tmp/airstatus.out";
          description = "Path where the airstatus daemon writes its JSON output.";
        };
      };

      config = lib.mkIf config.services.airstatus.enable {
        systemd.user.services.airstatus = {
          Unit.Description = "AirPods Battery Monitor";
          Service = {
            ExecStart = "${pkgs.local.airstatus}/bin/airstatus ${config.services.airstatus.outputFile}";
            Restart = "always";
            RestartSec = "3";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
