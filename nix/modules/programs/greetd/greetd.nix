# Login for sway hosts: greetd + tuigreet on the console, starting sway with
# no X server (imported by swayfxStack). X stacks keep LightDM.
# Switching display managers kills the running session: apply with
# `rebuild boot` (nh os boot) and reboot, not switch.
{ ... }:
{
  flake.modules.nixos.greetd =
    { lib, pkgs, ... }:
    {
      services.greetd = {
        enable = true;
        settings.default_session.command = "${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd sway";
      };
      # Unlocks the keyring at login (Proton Bridge's password on mail hosts)
      security.pam.services.greetd.enableGnomeKeyring = true;

      memory.earlyoomAvoid = [ "greetd" ];
    };
}
