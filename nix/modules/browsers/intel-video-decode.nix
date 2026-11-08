{
  # VA-API decode on Gen9.5 Intel GPUs (UHD 620/630), which have no AV1 or
  # VP9-in-MSE hw decode (the RDD process would burn CPU instead). Pairs with
  # the host's intel-media-driver and LIBVA_DRIVER_NAME=iHD.
  flake.modules.homeManager.intelVideoDecode =
    { ... }:
    {
      programs.firefox.profiles.default.settings = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "media.av1.enabled" = false;
      };

      # emacs-yt picks the stream itself (mpv runs with --ytdl=no), and
      # YouTube serves AV1 first, which dav1d then decodes on the CPU (~40 %
      # at 1080p). VP9 (profiles 0/2) and H.264 decode via VA-API here.
      # default.el loads after init.el, and a set value survives defcustom.
      programs.emacs.extraConfig = ''
        (setq yt-player-format "bv*[height<=1080][vcodec!^=av01]+ba/b")
      '';
    };
}
