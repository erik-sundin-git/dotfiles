{ ... }:
{
  flake.modules.nixos.bluetooth =
    { pkgs, ... }:
    {

      hardware.enableAllFirmware = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
        config.Policy = {
          AutoEnable = "true";
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
