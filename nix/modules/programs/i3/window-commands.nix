{ ... }:
{
  flake.modules.homeManager.i3 =
    { lib, wmWindowRules, ... }:
    {
      xsession.windowManager.i3.config.window.commands = map (r: {
        criteria = r.i3;
        inherit (r) command;
      }) (lib.filter (r: r ? i3) wmWindowRules);
    };
}
