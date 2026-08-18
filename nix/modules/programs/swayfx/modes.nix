{ ... }:
{
  flake.modules.homeManager.swayfx =
    {
      config,
      lib,
      mkModeNotif,
      ...
    }:
    let
      modifier = config.wayland.windowManager.sway.config.modifier;
      exit = {
        "Escape" = "mode default";
        "space" = "mode default";
      };
      launchNotif = mkModeNotif {
        modeTitle = "Launch";
        bindings = [
          {
            key = "e";
            description = "emacs";
          }
          {
            key = "l";
            description = "librewolf";
          }
          {
            key = "Esc/Spc";
            description = "exit";
          }
        ];
      };
      launchExit = {
        "Escape" = "exec ${launchNotif.exit}; mode default";
        "space" = "exec ${launchNotif.exit}; mode default";
      };
      powerNotif = mkModeNotif {
        modeTitle = "Power";
        bindings = [
          {
            key = "h";
            description = "hibernate";
          }
          {
            key = "r";
            description = "reboot";
          }
          {
            key = "s";
            description = "shutdown";
          }
          {
            key = "e";
            description = "logout";
          }
          {
            key = "Esc/Spc";
            description = "exit";
          }
        ];
      };
      powerExit = {
        "Escape" = "exec ${powerNotif.exit}; mode default";
        "space" = "exec ${powerNotif.exit}; mode default";
      };
      optionsNotif = mkModeNotif {
        modeTitle = "Options";
        bindings = [
          {
            key = "v";
            description = "toggle vpn";
          }
          {
            key = "Esc/Spc";
            description = "exit";
          }
        ];
      };
      optionsExit = {
        "Escape" = "exec ${optionsNotif.exit}; mode default";
        "space" = "exec ${optionsNotif.exit}; mode default";
      };
    in
    {
      wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
        "${modifier}+i" = "exec ${launchNotif.enter}; mode launch";
        "${modifier}+Shift+p" = "exec ${powerNotif.enter}; mode power";
        "${modifier}+o" = "exec ${optionsNotif.enter}; mode options";
        "${modifier}+r" = "mode resize";
      };

      wayland.windowManager.sway.config.modes = {
        launch = launchExit // {
          "e" = "exec ${launchNotif.exit}; exec emacs; mode default";
          "l" = "exec ${launchNotif.exit}; exec librewolf; mode default";
        };
        resize = exit // {
          "h" = "resize shrink width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize grow width 10 px or 10 ppt";
        };
        power = powerExit // {
          "h" = "exec ${powerNotif.exit}; exec systemctl hibernate; mode default";
          "r" = "exec ${powerNotif.exit}; exec systemctl reboot; mode default";
          "s" = "exec ${powerNotif.exit}; exec systemctl poweroff; mode default";
          "e" = "exec ${powerNotif.exit}; mode default; exec swaymsg exit";
        };
        options = optionsExit // {
          "v" = "exec ${optionsNotif.exit}; exec vpn-toggle; mode default";
        };
      };
    };
}
