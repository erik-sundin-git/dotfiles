{
  # VA-API decode on Gen9.5 Intel GPUs (UHD 620/630), which have no AV1 or
  # VP9-in-MSE hw decode (the RDD process would burn CPU instead). Pairs with
  # the host's intel-media-driver and LIBVA_DRIVER_NAME=iHD.
  flake.modules.homeManager.intelVideoDecode =
    { pkgs, ... }:
    {
      programs.firefox.profiles.default.settings = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "media.av1.enabled" = false;
      };
      programs.librewolf.profiles.default = {
        settings = {
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;
          "media.av1.enabled" = false;
          # Disabling WebM in MSE is what actually pushes YouTube off VP9;
          # the vp9 pref alone isn't enough. Tradeoff: 1080p cap on YouTube.
          "media.mediasource.vp9.enabled" = false;
          "media.mediasource.webm.enabled" = false;
        };
        extensions.packages = [ pkgs.nur.repos.rycee.firefox-addons.h264ify ];
      };
    };
}
