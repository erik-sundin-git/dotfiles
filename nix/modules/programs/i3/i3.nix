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
      c = config.colors;
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
            focused = {
              border = c.blue;
              background = c.blue;
              text = c.black;
              indicator = c.cyan;
              childBorder = c.blue;
            };
            focusedInactive = {
              border = c.black;
              background = c.black;
              text = c.foreground;
              indicator = c.black;
              childBorder = c.black;
            };
            unfocused = {
              border = c.black;
              background = c.background;
              text = c.brightBlack;
              indicator = c.black;
              childBorder = c.black;
            };
            urgent = {
              border = c.red;
              background = c.red;
              text = c.brightWhite;
              indicator = c.red;
              childBorder = c.red;
            };
          };
        };
      };
    };
}
