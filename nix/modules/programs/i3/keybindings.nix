{ inputs, ... }:
{
  # i3 binds and modes, translated from swayBindingsData (programs/swayfx/
  # bindings-data.nix) so i3 and sway share one bind list. Like sway, the
  # binds are set at normal priority, which drops HM's default i3 binds.
  flake.modules.homeManager.i3 =
    {
      config,
      lib,
      isLaptop,
      mkWmModes,
      swayBindingsData,
      ...
    }:
    let
      inherit (config.xsession.windowManager.i3.config) modifier;
      exec = "exec --no-startup-id";

      # Sway actions with an X11 replacement; null = no i3 equivalent (sway-help
      # and the claude launchers ask through fuzzel, which is Wayland-only).
      exact = {
        "exec fuzzel" = "${exec} dmenu_run";
        # foot is Wayland-only; the i3 stack installs alacritty
        "exec footclient" = "${exec} alacritty";
        "exec swaymsg exit" = "${exec} i3-msg exit";
        "exec osd volume up" = "${exec} pactl set-sink-volume @DEFAULT_SINK@ +5%";
        "exec osd volume down" = "${exec} pactl set-sink-volume @DEFAULT_SINK@ -5%";
        "exec osd volume mute" =
          "${exec} pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "exec osd mic mute" =
          "${exec} pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        "exec osd brightness up" = "${exec} brightnessctl set +5%";
        "exec osd brightness down" = "${exec} brightnessctl set 5%-";
        "exec sway-help" = null;
        "exec nix-add-package" = null;
        "exec claude-prompt" = null;
      };

      # Non-exec commands that mean the same in i3. Anything else throws, so a
      # new sway-only command in the data gets a mapping here.
      i3Commands = [
        "focus"
        "move"
        "layout"
        "workspace"
        "fullscreen"
        "floating"
        "scratchpad"
        "resize"
        "kill"
        "reload"
        "splith"
        "splitv"
      ];

      toI3 =
        action:
        if exact ? ${action} then
          exact.${action}
        else if lib.hasPrefix "exec osd " action || lib.hasPrefix "exec swaymsg" action then
          throw "i3 keybindings: no X11 mapping for sway action '${action}'"
        else if lib.hasPrefix "exec " action then
          "${exec} ${lib.removePrefix "exec " action}"
        else if lib.elem (lib.head (lib.splitString " " action)) i3Commands then
          action
        else
          throw "i3 keybindings: unknown sway action '${action}' (add it to programs/i3/keybindings.nix)";

      translate =
        binds: lib.filter (b: b.action != null) (map (b: b // { action = toI3 b.action; }) binds);

      bindToAttr =
        b: lib.nameValuePair (if b.mod or true then "${modifier}+${b.key}" else b.key) b.action;

      sectionBinds = translate (lib.concatMap (s: s.binds) swayBindingsData.sections);
      laptopBinds = translate swayBindingsData.laptopSection.binds;

      modes = mkWmModes {
        inherit modifier exec;
        modes = lib.mapAttrs (
          _: mode: mode // { bindings = translate mode.bindings; }
        ) swayBindingsData.modes;
      };
    in
    {
      imports = [ inputs.self.modules.homeManager.swayBindings ];

      xsession.windowManager.i3.config = {
        keybindings =
          lib.listToAttrs (map bindToAttr sectionBinds)
          // lib.optionalAttrs isLaptop (lib.listToAttrs (map bindToAttr laptopBinds))
          // modes.keybindings;
        inherit (modes) modes;
      };
    };
}
