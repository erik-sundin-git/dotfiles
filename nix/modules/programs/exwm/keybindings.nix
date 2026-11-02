{ inputs, ... }:
{
  # Translates swayBindingsData (programs/swayfx/bindings-data.nix) into EXWM
  # binds, written to my-exwm-nix.el as data:
  #   my-exwm-nix-global-keys  (KEY ACTION . ARGS)
  #   my-exwm-nix-modes        (NAME :title T :stay BOOL :binds ((KEY DESC ACTION . ARGS) ...))
  # my-exwm.el maps each ACTION to a command. A sway action with no
  # translation fails evaluation (the exwm-eval check catches it), so a new
  # sway bind needs a decision here.
  flake.modules.homeManager.exwm =
    {
      config,
      lib,
      isLaptop,
      swayBindingsData,
      exwmLisp,
      ...
    }:
    let
      inherit (exwmLisp) sym setq workspaceIndex;

      # Super+Shift+digit arrives as the shifted keysym, so the layout decides
      # the key name
      layout = config.systemConstants.keyboard.layout;
      shifted =
        if layout == "se" then
          {
            "1" = "!";
            "2" = "\"";
            "3" = "#";
            "4" = "¤";
            "5" = "%";
            "6" = "&";
            "7" = "/";
            "8" = "(";
            "9" = ")";
            "0" = "=";
            minus = "_";
          }
        else
          throw "exwm: no shifted-key table for keyboard layout '${layout}' (programs/exwm/keybindings.nix)";

      named = {
        Return = "<return>";
        space = "SPC";
        Escape = "<escape>";
        Left = "<left>";
        Right = "<right>";
        Up = "<up>";
        Down = "<down>";
        Print = "<print>";
      };

      # sway key syntax ("Shift+Return", mod) -> Emacs kbd syntax ("S-s-<return>")
      toKey =
        { key, mod }:
        let
          parts = lib.splitString "+" key;
          base = lib.last parts;
          mods = lib.init parts;
          shift = lib.elem "Shift" mods;
          ctrl = lib.elem "Ctrl" mods;
          unknownMods = lib.subtractLists [
            "Shift"
            "Ctrl"
          ] mods;
          # { name; shiftUsed; }: Shift folded into the key itself, or not
          resolved =
            if builtins.match "[a-z]" base != null then
              {
                name = if shift then lib.toUpper base else base;
                shiftUsed = shift;
              }
            else if builtins.match "[0-9]|minus" base != null then
              {
                name = if shift then shifted.${base} else if base == "minus" then "-" else base;
                shiftUsed = shift;
              }
            else if named ? ${base} then
              {
                name = named.${base};
                shiftUsed = false;
              }
            # XF86 keysyms keep their case
            else if lib.hasPrefix "XF86" base then
              {
                name = "<${base}>";
                shiftUsed = false;
              }
            else
              throw "exwm: no Emacs name for sway key '${key}'";
        in
        if unknownMods != [ ] then
          throw "exwm: unknown modifier in sway key '${key}'"
        else
          lib.concatStrings [
            (lib.optionalString ctrl "C-")
            (lib.optionalString (shift && !resolved.shiftUsed) "S-")
            (lib.optionalString mod "s-")
            resolved.name
          ];

      exact = {
        # No alacritty under EXWM: terminals are vterm buffers
        "exec alacritty" = [ (sym "vterm") ];
        "exec wofi --show drun" = [ (sym "launch-app") ];
        "exec nix-add-package" = [ (sym "nix-add-package") ];
        "exec claude-prompt" = [ (sym "claude-prompt") ];
        "exec swayosd-client --output-volume raise" = [ (sym "volume") (sym "up") ];
        "exec swayosd-client --output-volume lower" = [ (sym "volume") (sym "down") ];
        "exec swayosd-client --output-volume mute-toggle" = [ (sym "volume") (sym "mute") ];
        "exec swayosd-client --brightness raise" = [ (sym "brightness") (sym "up") ];
        "exec swayosd-client --brightness lower" = [ (sym "brightness") (sym "down") ];
        # Emacs is already running: launching it means going to its workspace
        "exec emacs" = [ (sym "workspace") (workspaceIndex "emacs") ];
        "exec systemctl hibernate" = [ (sym "power") "hibernate" ];
        "exec systemctl reboot" = [ (sym "power") "reboot" ];
        "exec systemctl poweroff" = [ (sym "power") "poweroff" ];
        "exec swaymsg exit" = [ (sym "logout") ];
        "kill" = [ (sym "kill") ];
        "focus left" = [ (sym "focus") (sym "left") ];
        "focus down" = [ (sym "focus") (sym "down") ];
        "focus up" = [ (sym "focus") (sym "up") ];
        "focus right" = [ (sym "focus") (sym "right") ];
        "move left" = [ (sym "swap") (sym "left") ];
        "move down" = [ (sym "swap") (sym "down") ];
        "move up" = [ (sym "swap") (sym "up") ];
        "move right" = [ (sym "swap") (sym "right") ];
        "focus mode_toggle" = [ (sym "focus-toggle") ];
        "splith" = [ (sym "split") (sym "right") ];
        "splitv" = [ (sym "split") (sym "below") ];
        "fullscreen toggle" = [ (sym "fullscreen") ];
        "floating toggle" = [ (sym "floating") ];
        "scratchpad show" = [ (sym "scratchpad-show") ];
        "move scratchpad" = [ (sym "scratchpad-hide") ];
        "reload" = [ (sym "reload") ];
      };

      # No EXWM equivalent, left unbound on purpose
      dropped = [
        "exec sway-help"
        "layout tabbed"
        "layout stacking"
        "layout toggle split"
        "focus parent"
      ];

      # Tools that only exist on Wayland/sway; a generic exec of one would
      # silently do nothing under X
      waylandTools = [
        "swaymsg"
        "wofi"
        "swayosd-client"
        "grim"
        "slurp"
        "wl-copy"
        "sway-help"
      ];

      # sway action -> [ ACTION ARGS... ], or null when dropped
      toAction =
        action:
        let
          wsNumber = builtins.match "workspace number ([0-9]+)" action;
          wsName = builtins.match "workspace ([^ ]+)" action;
          moveNumber = builtins.match "move container to workspace number ([0-9]+)" action;
          moveName = builtins.match "move container to workspace ([^ ]+)" action;
          resize = builtins.match "resize (shrink|grow) (width|height) .*" action;
          exec = builtins.match "exec (.+)" action;
          resizeDir = {
            "shrink width" = "narrower";
            "grow width" = "wider";
            "shrink height" = "shorter";
            "grow height" = "taller";
          };
        in
        if exact ? ${action} then
          exact.${action}
        else if lib.elem action dropped then
          null
        else if wsNumber != null then
          [ (sym "workspace") (lib.toInt (builtins.head wsNumber) - 1) ]
        else if wsName != null then
          [ (sym "workspace") (workspaceIndex (builtins.head wsName)) ]
        else if moveNumber != null then
          [ (sym "move-to-workspace") (lib.toInt (builtins.head moveNumber) - 1) ]
        else if moveName != null then
          [ (sym "move-to-workspace") (workspaceIndex (builtins.head moveName)) ]
        else if resize != null then
          [ (sym "resize") (sym resizeDir."${lib.concatStringsSep " " resize}") ]
        else if exec != null then
          let
            cmd = builtins.head exec;
          in
          if lib.elem (builtins.head (lib.splitString " " cmd)) waylandTools then
            throw "exwm: sway action '${action}' runs a Wayland-only tool; map it in programs/exwm/keybindings.nix"
          else
            [ (sym "exec") cmd ]
        else
          throw "exwm: no translation for sway action '${action}' (programs/exwm/keybindings.nix)";

      bindToKey =
        b:
        let
          a = toAction b.action;
        in
        lib.optional (a != null) (
          [
            (toKey {
              inherit (b) key;
              mod = b.mod or true;
            })
          ]
          ++ a
        );

      sections =
        swayBindingsData.sections ++ lib.optional isLaptop swayBindingsData.laptopSection;

      modeEntryKeys = lib.mapAttrsToList (name: m: [
        (toKey {
          key = lib.optionalString ((m.entryMod or "") != "") "${m.entryMod}+" + m.entryKey;
          mod = true;
        })
        (sym "menu")
        (sym name)
      ]) swayBindingsData.modes;

      modes = lib.mapAttrsToList (
        name: m:
        [
          (sym name)
          (sym ":title")
          m.title
          (sym ":stay")
          (m.stayInMode or false)
          (sym ":binds")
          (lib.concatMap (
            b:
            let
              a = toAction b.action;
            in
            lib.optional (a != null) (
              [
                (toKey {
                  inherit (b) key;
                  mod = false;
                })
                b.desc
              ]
              ++ a
            )
          ) m.bindings)
        ]
      ) swayBindingsData.modes;
    in
    {
      imports = [ inputs.self.modules.homeManager.swayBindings ];

      home.file.".emacs.d/exwm/my-exwm-nix.el".text = ''
        ${setq "my-exwm-nix-global-keys" (
          lib.concatMap (s: lib.concatMap bindToKey s.binds) sections ++ modeEntryKeys
        )}
        ${setq "my-exwm-nix-modes" modes}
      '';
    };
}
