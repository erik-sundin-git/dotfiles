{ ... }:
{
  flake.modules.homeManager.swayfx =
    { lib, wmWindowRules, ... }:
    {
      wayland.windowManager.sway.config.window.commands = map (r: {
        criteria = r.sway;
        inherit (r) command;
      }) (lib.filter (r: r ? sway) wmWindowRules);
    };
}
