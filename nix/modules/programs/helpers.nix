{ ... }:
{
  flake.modules.homeManager.uiHelpers =
    { pkgs, lib, ... }:
    let
      mkColors =
        {
          border,
          background ? border,
          text,
          indicator ? border,
          childBorder ? border,
        }:
        {
          inherit
            border
            background
            text
            indicator
            childBorder
            ;
        };

      # Notification listing a mode's keys while it is active. Needs dunst
      # (dunstctl closes it on exit).
      mkModeNotif =
        { modeTitle, bindings }:
        let
          keyWidth = lib.foldl (acc: b: lib.max acc (lib.stringLength b.key)) 0 bindings;
          rightPad =
            width: str:
            let
              padding = lib.max 0 (width - lib.stringLength str);
            in
            str + lib.concatStrings (builtins.genList (_: " ") padding);
          body = lib.concatStringsSep "\n" (map (b: "${rightPad keyWidth b.key}  ${b.description}") bindings);
        in
        {
          enter = pkgs.writeShellScript "mode-notif-enter" ''
            ${pkgs.libnotify}/bin/notify-send -u low -t 0 --print-id ${lib.escapeShellArg modeTitle} ${lib.escapeShellArg body} > "$XDG_RUNTIME_DIR/mode-notif"
          '';
          exit = pkgs.writeShellScript "mode-notif-exit" ''
            ${pkgs.dunst}/bin/dunstctl close "$(cat "$XDG_RUNTIME_DIR/mode-notif" 2>/dev/null)" 2>/dev/null
          '';
        };
    in
    {
      # theme.fontFamily's default; every UI module imports uiHelpers
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

      _module.args.mkColors = mkColors;

      # Title bar colors for i3 and sway (same option schema in both)
      _module.args.mkWmColors = c: {
        focused = mkColors {
          border = c.accent;
          text = c.background;
          indicator = c.cyan;
        };
        focusedInactive = mkColors {
          border = c.black;
          text = c.foreground;
        };
        unfocused = mkColors {
          border = c.black;
          background = c.background;
          text = c.brightBlack;
        };
        urgent = mkColors {
          border = c.red;
          text = c.urgentForeground;
        };
      };

      # Window rules for i3, sway and EXWM. Criteria differ (X11 class vs
      # Wayland app_id, and Electron apps report a generic app_id), so each
      # rule carries one per WM; a rule without one is skipped for that WM.
      # EXWM criteria are Emacs regexps, matched case-insensitively against
      # exwm-class-name / exwm-title (programs/exwm/exwm.nix translates the
      # command). Moves need --no-auto-back-and-forth: with
      # workspaceAutoBackAndForth, a move to the focused workspace would send
      # the window to the previous one instead.
      _module.args.wmWindowRules =
        let
          border = "border pixel 2";
        in
        [
          { sway.app_id = "firefox"; i3.class = "(?i)firefox"; command = border; }
          {
            sway = { app_id = "^firefox$"; title = "^Picture-in-Picture$"; };
            i3 = { class = "(?i)^firefox$"; title = "^Picture-in-Picture$"; };
            exwm = { class = "^firefox$"; title = "^Picture-in-Picture$"; };
            command = "floating enable";
          }
          { sway.app_id = "chromium"; i3.class = "(?i)chromium"; command = border; }
          { sway.app_id = "ungoogled-chromium"; command = border; }
          {
            sway = { app_id = "electron"; title = ".*FreeTube.*"; };
            i3.class = "FreeTube";
            command = border;
          }
          {
            sway = { app_id = "electron"; title = "^Proton Mail.*"; };
            i3.class = "Proton Mail";
            exwm.class = "^Proton Mail$";
            command = "move --no-auto-back-and-forth to workspace mail";
          }
        ];

      # Modal bindings (launch, power, ...) for i3 and sway from a data attrset
      # like swayBindingsData.modes: each mode shows its keys in a notification
      # while active. Returns { keybindings; modes; } for the WM's config.
      # A binding may have flags, such as "--no-repeat" (sway only), put
      # before its key; the notification shows the key alone.
      _module.args.mkWmModes =
        {
          modifier,
          modes,
          # i3 wants --no-startup-id so helper scripts don't spin the cursor
          exec ? "exec",
        }:
        let
          buildMode =
            name: mode:
            let
              notif = mkModeNotif {
                modeTitle = mode.title;
                bindings =
                  (map (b: {
                    key = b.key;
                    description = b.desc;
                  }) mode.bindings)
                  ++ [
                    {
                      key = "Esc/Spc";
                      description = "exit";
                    }
                  ];
              };
              exitAction = "${exec} ${notif.exit}; mode default";
              entryMod = mode.entryMod or "";
              entryPrefix = if entryMod == "" then "" else "${entryMod}+";
              innerBinds = lib.listToAttrs (
                map (
                  b:
                  lib.nameValuePair (lib.optionalString (b ? flags) "${b.flags} " + b.key) (
                    if mode.stayInMode or false then b.action else "${exec} ${notif.exit}; ${b.action}; mode default"
                  )
                ) mode.bindings
              );
            in
            {
              entryBind = lib.nameValuePair "${modifier}+${entryPrefix}${mode.entryKey}" "${exec} ${notif.enter}; mode ${name}";
              mode = lib.nameValuePair name (
                {
                  "Escape" = exitAction;
                  "space" = exitAction;
                }
                // innerBinds
              );
            };
          built = lib.mapAttrsToList buildMode modes;
        in
        {
          keybindings = lib.listToAttrs (map (m: m.entryBind) built);
          modes = lib.listToAttrs (map (m: m.mode) built);
        };

      _module.args.mkScreenshot =
        {
          name,
          args ? "",
        }:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            pkgs.maim
            pkgs.xclip
          ];
          text = ''
            mkdir -p ~/Pictures/Screenshots
            f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
            # A cancelled maim -s must not leave an empty file behind
            maim ${args} "$f" || { rm -f "$f"; exit 0; }
            xclip -selection clipboard -t image/png < "$f"
          '';
        };

      _module.args.waylandScreenshots =
        let
          mkGrim =
            { name, area }:
            pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = [
                pkgs.grim
                pkgs.wl-clipboard
              ]
              ++ lib.optional area pkgs.slurp;
              text = ''
                mkdir -p ~/Pictures/Screenshots
                f=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
                ${
                  if area then
                    ''
                      # Cancelling slurp exits non-zero; bail before touching $f
                      geom=$(slurp) || exit 0
                      grim -g "$geom" "$f"
                    ''
                  else
                    ''grim "$f"''
                }
                wl-copy --type image/png < "$f"
              '';
            };
        in
        [
          (mkGrim {
            name = "screenshot-area";
            area = true;
          })
          (mkGrim {
            name = "screenshot-full";
            area = false;
          })
        ];

      # Polkit authentication agent as a user service bound to the session
      # target. Without one, polkit prompts (udisks mounts, flatpak, GUI
      # privilege requests) fail silently on sway and i3.
      _module.args.mkPolkitAgent = target: {
        Unit = {
          Description = "polkit-gnome authentication agent";
          PartOf = [ target ];
          After = [ target ];
        };
        Service = {
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
        };
        Install.WantedBy = [ target ];
      };

      _module.args.hexToRgba =
        hex: alpha:
        let
          fromHex =
            s:
            let
              d = {
                "0" = 0;
                "1" = 1;
                "2" = 2;
                "3" = 3;
                "4" = 4;
                "5" = 5;
                "6" = 6;
                "7" = 7;
                "8" = 8;
                "9" = 9;
                "a" = 10;
                "b" = 11;
                "c" = 12;
                "d" = 13;
                "e" = 14;
                "f" = 15;
              };
              hi = d.${lib.toLower (lib.substring 0 1 s)};
              lo = d.${lib.toLower (lib.substring 1 1 s)};
            in
            hi * 16 + lo;
          h = lib.removePrefix "#" hex;
        in
        "rgba(${toString (fromHex (lib.substring 0 2 h))}, ${toString (fromHex (lib.substring 2 2 h))}, ${
          toString (fromHex (lib.substring 4 2 h))
        }, ${alpha})";

      _module.args.mkModeNotif = mkModeNotif;
    };
}
