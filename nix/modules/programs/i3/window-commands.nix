{ ... }:
{
  flake.modules.homeManager.i3 =
    { ... }:
    {
      xsession.windowManager.i3.config.window.commands = [
        {
          criteria.class = "(?i)firefox";
          command = "border pixel 2";
        }
        {
          criteria.class = "(?i)librewolf";
          command = "border pixel 2";
        }
        {
          criteria.class = "(?i)chromium";
          command = "border pixel 2";
        }
        {
          criteria.class = "FreeTube";
          command = "border pixel 2";
        }
        {
          criteria.class = "Proton Mail";
          command = "move to workspace mail";
        }
        {
          criteria.class = "^[Ee]macs$";
          command = "move to workspace emacs";
        }
      ];
    };
}
