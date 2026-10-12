{ inputs, ... }:
{

  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    {
      imports = [ inputs.self.modules.nixos.pulseaudio ];

      hardware.enableAllFirmware = true;
      services.pulseaudio.extraConfig = "load-module module-switch-on-connect";
      services.upower.enable = true;

      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
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
