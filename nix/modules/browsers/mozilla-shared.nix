{ ... }:
{
  # Shared Firefox/LibreWolf profile pieces, exposed as the `mozillaShared`
  # module arg and merged into each browser's "default" profile.
  flake.modules.homeManager.mozillaShared =
    { config, pkgs, ... }:
    let
      c = config.theme;
      r = toString c.rounding;
    in
    {
      _module.args.mozillaShared = {
        search = {
          force = true;
          default = "ddg";
          privateDefault = "ddg";

          engines = {
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };

            "Nix Options" = {
              urls = [
                {
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };

            "NixOS Wiki" = {
              urls = [
                {
                  template = "https://wiki.nixos.org/w/index.php";
                  params = [
                    {
                      name = "search";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nw" ];
            };
          };
        };

        settings = {
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "browser.uidensity" = 1;
          "extensions.autoDisableScopes" = 0;
          "browser.translations.automaticallyPopup" = false;

          # Minimal UI: vertical tabs as an icon sidebar that expands on hover,
          # no titlebar/bookmarks strip; userChrome below does the rest.
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          "sidebar.visibility" = "expand-on-hover";
          # An empty list gets reset to the defaults, so keep one tool.
          "sidebar.main.tools" = "history";
          # Start new windows with the launcher shown; hidden, there's nothing
          # to hover (and #sidebar-button, the usual toggle, is hidden below).
          "sidebar.backupState" = builtins.toJSON {
            command = "";
            panelOpen = false;
            launcherExpanded = false;
            launcherVisible = true;
          };
          "browser.tabs.inTitlebar" = 0;
          "browser.toolbars.bookmarks.visibility" = "never";

          # VA-API hardware video decode; AV1 off since Intel UHD 620 can't decode it in hardware
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          "media.av1.enabled" = false;
          "gfx.webrender.all" = true;
        };

        # Recolors compact-dark from config.theme and strips the nav bar down to
        # the urlbar, extensions and menu (vimium covers back/forward/reload).
        userChrome = ''
          :root {
            --toolbar-bgcolor: ${c.background} !important;
            --toolbar-color: ${c.foreground} !important;
            --toolbar-field-background-color: ${c.superDark} !important;
            --toolbar-field-focus-background-color: ${c.superDark} !important;
            --toolbar-field-color: ${c.foreground} !important;
            --toolbar-field-focus-color: ${c.foreground} !important;
            --toolbar-field-border-color: transparent !important;
            --toolbar-field-focus-border-color: ${c.blue} !important;
            --sidebar-background-color: ${c.superDark} !important;
            --sidebar-text-color: ${c.foreground} !important;
            --tab-selected-bgcolor: ${c.black} !important;
            --tab-selected-textcolor: ${c.foreground} !important;
            --focus-outline-color: ${c.blue} !important;
            --arrowpanel-background: ${c.background} !important;
            --arrowpanel-color: ${c.foreground} !important;
            --arrowpanel-border-color: ${c.black} !important;
            --tab-border-radius: ${r}px !important;
            --toolbarbutton-border-radius: ${r}px !important;
            --urlbar-margin-inline: 0 !important;
            --chrome-content-separator-color: transparent !important;
          }

          #navigator-toolbox,
          #nav-bar {
            background-color: var(--toolbar-bgcolor) !important;
            border: none !important;
          }

          #nav-bar {
            padding-block: 2px !important;
          }

          #urlbar-background {
            border-radius: ${r}px !important;
          }

          #back-button,
          #forward-button,
          #reload-button,
          #stop-button,
          #home-button,
          #firefox-view-button,
          #alltabs-button,
          #fxa-toolbar-menu-button,
          #sidebar-button,
          #nav-bar toolbarspring,
          #tracking-protection-icon-container,
          #identity-icon-label {
            display: none !important;
          }
        '';

        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          darkreader
          sponsorblock
          consent-o-matic
          vimium
          lockedin-yt
          (buildFirefoxXpiAddon {
            pname = "besttimetracker";
            version = "4.3.0";
            addonId = "{a8cf72f7-09b7-4cd4-9aaa-7a023bf09916}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4799246/besttimetracker-4.3.0.xpi";
            sha256 = "sha256-EQGwx7ps+QV8HdLGQPcNHCWkj10IhDGthrOoYjyQwO0=";
            meta = { };
          })
        ];
      };
    };
}
