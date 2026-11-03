{ inputs, ... }:
{
  # yt (github:erik-sundin-git/emacs-yt): the YouTube subscription feed in
  # Emacs, played in mpv or VLC. Installs mpv and yt-export-cookies, and adds
  # the elisp package to programs.emacs; post-init.el binds C-c y. Sign in
  # with M-x yt-login using a Chromium profile used only for YouTube.
  flake.modules.homeManager.emacsYoutube = {
    imports = [ inputs.emacs-yt.homeModules.default ];
    programs.yt = {
      enable = true;
      installElisp = true;
      # mpv's window floats on top of the other windows, at 960x540.
      swayWindowRule = true;
    };
  };
}
