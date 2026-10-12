{ ... }:
{
  # Shared Firefox/LibreWolf profile pieces, exposed as the `mozillaShared`
  # module arg and merged into each browser's "default" profile.
  flake.modules.homeManager.mozillaShared =
    { pkgs, ... }:
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

          # VA-API hardware video decode; AV1 off since Intel UHD 620 can't decode it in hardware
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          "media.av1.enabled" = false;
          "gfx.webrender.all" = true;
        };

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
