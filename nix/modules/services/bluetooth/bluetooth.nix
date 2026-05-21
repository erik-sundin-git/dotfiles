{ ... }:
{
  flake.modules.homeManager.bluetooth =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.blueman ];
    };

  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    {

      hardware.enableAllFirmware = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings.Policy = {
          AutoEnable = "true";
        };
      };

      services.pipewire.wireplumber.extraConfig."51-bluez-config" = {
        "monitor.bluez.properties" = {
          "bluez5.auto-connect" = [ "a2dp_sink" ];
          "bluez5.default.rate" = 48000;
          "bluez5.default.duration" = 1024;
        };
      };

      #services.blueman.enable = true;
      # withApplet = true (default) creates a systemd user unit override that
      # adds a second ExecStart= to the package's own Type=dbus unit — systemd
      # refuses that. D-Bus activation still works via the package unit;
      # blueman-applet starts from Hyprland exec-once instead.
      #      services.blueman.withApplet = false;
    };
}
