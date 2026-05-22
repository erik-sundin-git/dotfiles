{ ... }:
{

  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    {

      hardware.enableAllFirmware = true;
      services.pulseaudio.enable = true;
      services.pulseaudio.extraConfig = "load-module module-switch-on-connect";
      services.upower.enable = true;

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings.Policy = {
          AutoEnable = "true";
        };
      };

      services.blueman.enable = true;
      systemd.services.bluetooth-resume-reset = {
        description = "Restart bluetooth on resume to clear stale bluez objects";
        wantedBy = [ "post-resume.target" ];
        after = [ "post-resume.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart bluetooth.service";
        };
      };
    };
}
