{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

{
  flake.modules.nixos.i3 =
    { pkgs, ... }:
    {

      services.xserver = {
        enable = true;
        desktopManager = {
          xterm.enable = false;
        };
        windowManager.i3.enable = true;
      };
      services.displayManager.defaultSession = "none+i3";
      environment.systemPackages = with pkgs; [
        xfce.xfce4-screenshooter
      ];
    };

  flake.modules.homeManager.i3 =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      xsession.windowManager.i3 = {
        enable = true;
        package = pkgs.i3;

        extraConfig = "
    default_border pixel 3
    for_window [class='Emacs'] border normal 1

    exec '${pkgs.synergy}'";

        config = {
          floating.criteria = [
            { class = "steam_app_2429640"; }
            { class = "arena-tracker"; }
          ];

          modifier = "Mod4";
          fonts = lib.mkForce { size = 12.0; };

          gaps = {
            inner = 0;
            outer = 0;
            top = 0;
          };

          bars = [
            {
              fonts = {
                size = 13.0;
              };
              colors.background = "#000000";
              position = "top";
              statusCommand = "${pkgs.i3blocks}/bin/i3blocks -c ~/.config/i3blocks/top";
            }
          ];

          workspaceAutoBackAndForth = true;

          # Start on workspace 1
          defaultWorkspace = "1";

          # Assign programs to specific workspaces.

          assigns = {
            "9: Audio" = [
              { class = "Spotify"; }
              { class = "Pavucontrol"; }
            ];
          };

          startup = [
            { command = "nitrogen --restore"; }
          ];

          modes = {
            resize = {
              "j" = "resize grow height 10 px or 10 ppt";
              Escape = "mode default";
              "h" = "resize shrink width 10 px or 10 ppt";
              "space" = "mode default";
              "l" = "resize grow width 10 px or 10 ppt";
              "k" = "resize shrink height 10 px or 10 ppt";
            };
          };
        };
      };

      programs.i3blocks = {
        enable = true;
        bars = {
          top = {
            fonts = {
              size = 16;
            };
            time = {
              command = "date +%r";
              interval = 1;
            };
            # Make sure this block comes after the time block
            date = lib.hm.dag.entryAfter [ "time" ] {
              command = "date '+%a %d %B'";
              interval = 5;
            };
          };
        };
      };

    };
}
