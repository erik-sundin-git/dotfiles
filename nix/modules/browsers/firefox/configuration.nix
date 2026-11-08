{ lib, ... }:
{
  flake.modules.homeManager.firefox =
    { mozillaShared, ... }:
    {
      programs.firefox = {
        enable = true;
        # Legacy path; HM 26.05 defaults to XDG only for new stateVersions.
        configPath = ".mozilla/firefox";

        policies = {
          DontCheckDefaultBrowser = true;
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
        };

        profiles."default" = {
          # DDG's Swedish results are poor.
          search = mozillaShared.search // {
            default = "Startpage";
            privateDefault = "Startpage";
          };
          settings = mozillaShared.settings // {
            "browser.startup.homepage" = "https://www.youtube.com";
          };
          extensions.packages = mozillaShared.extensions;
          userChrome = mozillaShared.userChrome;
        };
      };
    };

  # Firefox as the default browser, in /etc/xdg/mimeapps.list. Not HM's
  # xdg.mimeApps: that would take over ~/.config/mimeapps.list, where apps
  # (claude-code, Proton Mail, Discord, ...) register their own URL handlers.
  flake.modules.nixos.commonDesktop.xdg.mime.defaultApplications = lib.genAttrs [
    "text/html"
    "application/xhtml+xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ] (_: "firefox.desktop");
}
