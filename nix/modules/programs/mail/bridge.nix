{ ... }:
{
  flake.modules.homeManager.mail =
    { pkgsUnstable, ... }:
    {
      # Headless Bridge as a user service. It stays on HM's default
      # graphical-session.target on purpose: it needs only the session D-Bus and
      # the keyring LightDM's PAM unlocks, not a display, so outliving the sway
      # session (see the CLAUDE.md gotcha) is harmless. Unstable because Proton
      # retires old Bridge versions. Never run the Bridge GUI next to it: only
      # one instance can hold the lock.
      services.protonmail-bridge = {
        enable = true;
        package = pkgsUnstable.protonmail-bridge;
      };
      systemd.user.services.protonmail-bridge.Service.RestartSec = 5;
    };
}
