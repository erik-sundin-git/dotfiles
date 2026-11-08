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
    };
}
