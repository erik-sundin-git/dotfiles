{ inputs, ... }:
{
  flake.modules.homeManager.librewolf =
    {
      pkgs,
      pkgsUnstable,
      mozillaShared,
      ...
    }:
    {
      imports = [ inputs.self.modules.homeManager.mozillaShared ];

      home.file.".librewolf/librewolf.overrides.cfg".text = ''
        lockPref("browser.theme.content-theme", 0);
        lockPref("browser.theme.toolbar-theme", 0);
      '';

      programs.librewolf = {
        enable = true;
        package = pkgsUnstable.librewolf;

        policies.DontCheckDefaultBrowser = true;

        profiles."default".search = mozillaShared.search;

        profiles."default".settings = mozillaShared.settings // {
          # Force sites to serve H.264 instead of AV1/VP9 so VAAPI can decode on
          # GPUs that lack AV1/VP9 hw decode (otherwise the RDD process burns CPU).
          # Disabling WebM in MSE is what actually pushes YouTube off VP9 — the
          # vp9-specific pref alone isn't enough since YT detects support via
          # other paths. Tradeoff: 1080p cap on YouTube.
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
          "gfx.webrender.compositor" = true;
          "layers.acceleration.force-enabled" = true;

          # Reduce scroll latency — remove APZ frame delay and shorten transaction timeout
          "apz.frame_delay.enabled" = false;
          "mousewheel.transaction.timeout" = 200;
        };

        profiles."default".extensions.packages = mozillaShared.extensions ++ [
          pkgs.nur.repos.rycee.firefox-addons.h264ify
        ];
      };

    };
}
