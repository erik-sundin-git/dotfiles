{ ... }:
{
  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    {
      hardware.enableAllFirmware = true;
      # A2DP only: PulseAudio 17's native HFP backend segfaults when a headset
      # reports its battery level (parse_percentage in libbluez5-util). With
      # headset=ofono and no ofono running, no headset profiles get registered,
      # so the headset mic doesn't work over bluetooth.
      services.pulseaudio.extraConfig = ''
        load-module module-switch-on-connect
        unload-module module-bluetooth-discover
        load-module module-bluez5-discover headset=ofono enable_native_hsp_hs=false enable_native_hfp_hf=false
      '';
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
