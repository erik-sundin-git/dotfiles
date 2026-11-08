{ inputs, ... }:
{
  # EXWM: Emacs as the X window manager. The session runs the regular Emacs
  # (programs.emacs, with exwm added to its packages) and loads
  # ~/.emacs.d/exwm/init.el after the normal init, so ~/.emacs.d itself is
  # untouched and nothing EXWM-related loads outside this session. The elisp
  # lives in nix/assets/exwm/; nix only writes data into my-exwm-nix.el
  # (keybindings.nix adds the binds translated from swayBindingsData).
  flake.modules.nixos.exwm =
    { ... }:
    {
      # A plain window-manager session (not HM's xsession like i3). The
      # session wrapper sources /etc/profile, so exwm-session is on PATH, and
      # it starts graphical-session.target (via
      # nixos-fake-graphical-session.target) before the WM and stops it after,
      # so dunst, xss-lock, gammastep, polkit and blueman follow the session.
      services.xserver.windowManager.session = [
        {
          name = "exwm";
          start = ''
            exwm-session &
            waitPID=$!
          '';
        }
      ];
      services.displayManager.defaultSession = "none+exwm";

      # i3lock-color (homeManager.i3Lock) authenticates through PAM
      security.pam.services.i3lock = { };

      # Flat pointer acceleration like sway. commonHome's .xprofile still sets
      # libinput Accel Speed 0.5 on X, so the speed differs from sway's 0.
      services.libinput = {
        mouse.accelProfile = "flat";
        touchpad = {
          accelProfile = "flat";
          tapping = true;
          naturalScrolling = false;
        };
      };

      # Emacs is the window manager and X its display: killing either ends
      # the session
      memory.earlyoomAvoid = [
        "emacs(-[0-9.]+)?"
        "X"
        "Xorg"
      ];
    };

  flake.modules.homeManager.exwm =
    {
      config,
      lib,
      pkgs,
      isLaptop,
      mkScreenshot,
      mkPolkitAgent,
      wmWindowRules,
      osConfig ? { },
      ...
    }:
    let
      # Nix values -> elisp read syntax, for the data in my-exwm-nix.el.
      # Strings go through toJSON, which elisp reads as string literals.
      sym = s: { __elispSymbol = s; };
      toElisp =
        v:
        if v == null then
          "nil"
        else if builtins.isBool v then
          (if v then "t" else "nil")
        else if builtins.isInt v then
          toString v
        else if builtins.isString v then
          builtins.toJSON v
        else if builtins.isList v then
          "(" + lib.concatMapStringsSep " " toElisp v + ")"
        else if v ? __elispSymbol then
          v.__elispSymbol
        else
          throw "exwm: can't write ${builtins.typeOf v} as elisp";
      setq = name: value: "(setq ${name} '${toElisp value})";

      # Workspace index -> name. sway's named workspaces get fixed slots
      # after 1..10; keys, window rules and the bar all use this list.
      workspaceNames = map toString (lib.range 1 10) ++ [
        "mail"
        "emacs"
      ];
      workspaceIndex =
        name:
        let
          i = lib.lists.findFirstIndex (n: n == name) null workspaceNames;
        in
        if i == null then throw "exwm: no workspace named ${name}" else i;

      # claude-code is installed system-wide (profiles, live ISO); same test
      # as waybar
      hasClaude = lib.any (p: lib.getName p == "claude-code") (
        osConfig.environment.systemPackages or [ ]
      );

      # wmWindowRules entries with an exwm field, each as
      # (CLASS-REGEXP TITLE-REGEXP . exwm-manage-configurations plist).
      ruleProps =
        command:
        let
          ws = builtins.match "move (--no-auto-back-and-forth )?to workspace (.+)" command;
        in
        if command == "floating enable" then
          [
            (sym "floating")
            true
          ]
        else if ws != null then
          [
            (sym "workspace")
            (workspaceIndex (lib.last ws))
          ]
        else if lib.hasPrefix "border " command then
          [ ]
        else
          throw "exwm: no translation for window rule command '${command}'";
      sharedRules = map (r: [
        r.exwm.class
        (r.exwm.title or null)
      ] ++ ruleProps r.command) (lib.filter (r: r ? exwm) wmWindowRules);
      exwm-session = pkgs.writeShellApplication {
        name = "exwm-session";
        text = ''
          # Started by LightDM (nixos.exwm). -l loads after the user's init.
          # The daemon doesn't autostart here, but one left over from another
          # session (e.g. sway before switching stacks) would hold the server
          # socket and the session files.
          systemctl --user stop emacs.service || true
          # The directory is passed in: init.el's load-file-name would be the
          # store path behind the symlink, not where my-exwm-nix.el is.
          # EXWM_SESSION lets post-init.el skip what mustn't run in the WM
          # Emacs (package auto-updates).
          export EXWM_SESSION=1
          exec ${config.programs.emacs.finalPackage}/bin/emacs \
            --eval "(setq my-exwm-directory \"$HOME/.emacs.d/exwm/\")" \
            -l "$HOME/.emacs.d/exwm/init.el"
        '';
      };
    in
    {
      imports = with inputs.self.modules.homeManager; [
        uiHelpers
        claudeLaunchers
      ];

      assertions = [
        {
          assertion = !lib.hasInfix "pgtk" config.programs.emacs.package.name;
          message = "EXWM needs an X11 Emacs, but programs.emacs.package is ${config.programs.emacs.package.name}. Don't combine exwmStack with a Wayland stack.";
        }
      ];

      # Stable 0.35 from ELPA; the elpa-devel snapshot isn't reliably fetchable
      programs.emacs.extraPackages = epkgs: [ epkgs.elpaPackages.exwm ];

      # The EXWM Emacs runs the server (init.el), so a daemon would only race
      # it for the socket and for easysession/recentf/savehist files
      services.emacs.startWithUserSession = false;

      # Unscaled under EXWM, overriding commonHome's 1.5x on laptops.
      # Explicit, since without Xft.dpi Emacs falls back to the screen's
      # physical DPI.
      xresources.properties."Xft.dpi" = lib.mkForce 96;

      home.file =
        lib.genAttrs
          (map (f: ".emacs.d/exwm/${f}") [
            "init.el"
            "my-exwm.el"
            "my-exwm-bar.el"
          ])
          (name: {
            source = "${inputs.self}/nix/assets/exwm/${baseNameOf name}";
          })
        // {
          ".emacs.d/exwm/my-exwm-nix.el".text = lib.mkMerge [
            (lib.mkBefore ''
              ;;; my-exwm-nix.el --- Generated by nix (programs/exwm) -*- no-byte-compile: t; lexical-binding: t; coding: utf-8 -*-
            '')
            ''
              ${setq "my-exwm-nix-workspace-names" workspaceNames}
              ${setq "my-exwm-nix-window-rules" sharedRules}
              ${setq "my-exwm-nix-laptop" isLaptop}
              ${setq "my-exwm-nix-thermal-path" config.systemConstants.thermalZonePath}
              ${setq "my-exwm-nix-claude-usage" (
                if hasClaude then lib.getExe pkgs.local.claude-usage else null
              )}
            ''
          ];
        };

      _module.args.exwmLisp = {
        inherit
          sym
          toElisp
          setq
          workspaceIndex
          ;
      };

      systemd.user.services.polkit-agent = mkPolkitAgent "graphical-session.target";

      # Tray icon in exwm-systemtray
      services.blueman-applet.enable = true;

      # Suspend after 30 min idle on laptops, like swayidle: i3Lock locks at
      # 20 min, xautolock's killer runs 10 min later
      services.screen-locker.xautolock.extraOptions = lib.mkIf isLaptop [
        "-killtime 10"
        "-killer '${pkgs.systemd}/bin/systemctl suspend'"
      ];

      home.packages = [
        exwm-session
        pkgs.xclip
        pkgs.xrandr
        pkgs.pavucontrol
        (mkScreenshot {
          name = "screenshot-area";
          args = "-s";
        })
        (mkScreenshot { name = "screenshot-full"; })
      ]
      ++ lib.optionals isLaptop [ pkgs.brightnessctl ];
    };
}
