{ ... }:
{
  flake.modules.homeManager.swayfx =
    { ... }:
    {
      wayland.windowManager.sway.config.window.commands = [
        {
          criteria.app_id = "firefox";
          command = "border pixel 2";
        }
        {
          criteria.app_id = "librewolf";
          command = "border pixel 2";
        }
        {
          criteria.app_id = "chromium";
          command = "border pixel 2";
        }
        {
          criteria.app_id = "ungoogled-chromium";
          command = "border pixel 2";
        }
        {
          criteria = {
            app_id = "electron";
            title = ".*FreeTube.*";
          };
          command = "border pixel 2";
        }
        {
          criteria = {
            app_id = "electron";
            title = "^Proton Mail.*";
          };
          command = "move to workspace mail";
        }
        {
          criteria.app_id = "^[Ee]macs$";
          command = "move to workspace emacs";
        }
      ];
    };
}
