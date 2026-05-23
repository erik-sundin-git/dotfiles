{ lib, ... }:
{
  flake.modules.homeManager.librewolf =
    {
      pkgs,
      config,
      lib,
      ...
    }:

    {
      home.sessionVariables = lib.mkMerge [
        { MOZ_USE_XINPUT2 = "1"; }
        (lib.mkIf (builtins.any (v: v.enable or false) (
          builtins.attrValues config.wayland.windowManager
        )) { MOZ_ENABLE_WAYLAND = "1"; })
      ];

      home.file.".librewolf/librewolf.overrides.cfg".text = ''
        lockPref("browser.theme.content-theme", 0);
        lockPref("browser.theme.toolbar-theme", 0);
      '';

      programs.librewolf = {
        enable = true;

        policies.DontCheckDefaultBrowser = true;

        profiles."default".search = {
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

        profiles."default".settings = {
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "browser.uidensity" = 1;
          "extensions.autoDisableScopes" = 0;

          # Hardware video decoding via VAAPI (offloads the rdd process to GPU)
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;

          # Force sites to serve H.264 instead of AV1/VP9 so VAAPI can decode on
          # GPUs that lack AV1/VP9 hw decode (otherwise the RDD process burns CPU).
          # Disabling WebM in MSE is what actually pushes YouTube off VP9 — the
          # vp9-specific pref alone isn't enough since YT detects support via
          # other paths. Tradeoff: 1080p cap on YouTube.
          "media.av1.enabled" = false;
          "media.mediasource.vp9.enabled" = false;
          "media.mediasource.webm.enabled" = false;

          # Fewer content processes — less RAM and IPC overhead
          #          "dom.ipc.processCount" = 4;

          # RAM-only cache — faster, avoids disk thrash
          "browser.cache.disk.enable" = false;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = -1;

          # Unload background tabs under memory pressure
          "browser.tabs.unloadOnLowMemory" = true;

          # Keep cookies across restarts (Librewolf clears them by default)
          "privacy.clearOnShutdown.cookies" = false;
          "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;

          # Write session state less often (default 15 s)
          "browser.sessionstore.interval" = 60000;

          # Start rendering immediately instead of waiting 250 ms
          "nglayout.initialpaint.delay" = 0;
          "nglayout.initialpaint.delay_in_oopif" = 0;

          # GPU compositing via WebRender — offloads compositing from CPU to iGPU
          "gfx.webrender.all" = true;
          "gfx.webrender.compositor" = true;
          "layers.acceleration.force-enabled" = true;

          # Reduce scroll latency — remove APZ frame delay and shorten transaction timeout
          "apz.frame_delay.enabled" = false;
          "mousewheel.transaction.timeout" = 200;

          "browser.translations.automaticallyPopup" = false;
        };

        profiles."default".extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          darkreader
          sponsorblock
          consent-o-matic
          vimium
          lockedin-yt
          h264ify
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
