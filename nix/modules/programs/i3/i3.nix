{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.homeManager.i3 =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      c = config.theme;
      mkColors =
        {
          border,
          background ? border,
          text,
          indicator ? border,
          childBorder ? border,
        }:
        { inherit border background text indicator childBorder; };
      mkScreenshot = { name, args ? "" }: pkgs.writeShellScriptBin name ''
        mkdir -p ~/Pictures/Screenshots
        f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
        maim ${args} | tee "$f" | xclip -selection clipboard -t image/png
      '';
    in
    {
      home.packages =
        [
          pkgs.blueman
          pkgs.maim
          pkgs.xclip
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.xdg-desktop-portal
          pkgs.xdg-desktop-portal-gtk
          (mkScreenshot { name = "screenshot-area"; args = "-s"; })
          (mkScreenshot { name = "screenshot-full"; })
        ]
        ++ lib.optionals (config.systemConstants.system.type == "laptop") [
          pkgs.brightnessctl
        ];

      services.redshift = {
        enable = true;
        latitude = config.systemConstants.latitude;
        longitude = config.systemConstants.longitude;
        temperature.day = 6500;
        temperature.night = 3500;
      };

      xsession.windowManager.i3 = {
        enable = true;

        config = {
          modifier = "Mod4";

          startup = [
            { command = "nitrogen --restore"; }
            { command = "blueman-applet"; notification = false; }
            { command = "systemctl --user import-environment DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS && systemctl --user restart xdg-desktop-portal-gtk xdg-desktop-portal"; notification = false; }
            { command = "pkill polybar; polybar main"; always = true; notification = false; }
            { command = "pkill picom; picom"; always = true; notification = false; }
          ];

          gaps = {
            inner = 0;
            outer = 0;
            top = 0;
          };

          bars = [ ];
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "1";

          colors = {
            focused = mkColors { border = c.blue; text = c.black; indicator = c.cyan; };
            focusedInactive = mkColors { border = c.black; text = c.foreground; };
            unfocused = mkColors { border = c.black; background = c.background; text = c.brightBlack; };
            urgent = mkColors { border = c.red; text = c.brightWhite; };
          };
        };
      };
    };
}
