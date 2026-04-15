{ ... }:

{
  flake.modules.homeManager.hyprland-windowrules =
    { ... }:
    {
      wayland.windowManager.hyprland.extraConfig = ''
        permission = /usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland, screencopy, allow
        permission = /usr/(bin|local/bin)/hyprpm, plugin, allow

        windowrule {
            name = suppress-maximize-events
            match:class = .*
            suppress_event = maximize
        }

        windowrule {
            name = fix-xwayland-drags
            match:class = ^$
            match:title = ^$
            match:xwayland = true
            match:float = true
            match:fullscreen = false
            match:pin = false
            no_focus = true
        }

        windowrule {
            name = opacitystuff
            match:class = Emacs
            opacity = 0.9
        }

        windowrule {
            name = ncspot
            match:title = io.github.hrkfdn.ncspot
            workspace = 5
        }

        windowrule {
            name = blueman
            match:class = blueman-manager
            workspace = 5
        }

        windowrule {
            name = alacritty
            match:class = Alacritty
            opacity = 0.8
        }

        windowrule {
            name = move-hyprland-run
            match:class = hyprland-run
            move = 20 monitor_h-120
            float = yes
        }
      '';
    };
}
