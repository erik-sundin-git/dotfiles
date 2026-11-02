{
  # GTNH client for every host with the gaming module (which installs Prism
  # and /etc/jdk21): a rofi (drun) entry that launches the instance directly,
  # and a one-time install of the official MultiMC/Prism zip when the instance
  # folder is missing. Bumping `version` installs the new pack alongside the
  # old instance; it never touches an existing one.
  flake.modules.homeManager.gtnhLauncher =
    { config, pkgs, ... }:
    let
      version = "2.8.4";
      instance = "GT_New_Horizons_${version}_Java_17-25";
      url = "https://downloads.gtnewhorizons.com/Multi_mc_downloads/${instance}.zip";
      prism = "${config.xdg.dataHome}/PrismLauncher";

      gtnh-install = pkgs.writeShellApplication {
        name = "gtnh-install";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          gnused
          unzip
        ];
        text = ''
          dest="${prism}/instances/${instance}"
          if [ -e "$dest" ]; then
            exit 0
          fi

          mkdir -p "${config.xdg.cacheHome}" "${prism}/instances" "${prism}/icons"
          tmp=$(mktemp -d "${config.xdg.cacheHome}/gtnh-install.XXXXXX")
          trap 'rm -rf "$tmp"' EXIT

          curl -fL --retry 3 -o "$tmp/pack.zip" "${url}"
          unzip -q "$tmp/pack.zip" -d "$tmp"
          src="$tmp/GT New Horizons ${version}"

          # The pack ships Prism defaults; pin Java to the GC-stable JDK and
          # give GTNH the memory and GC it needs
          sed -i -E '/^(name|AutomaticJava|JavaPath|OverrideJavaLocation|OverrideJavaArgs|JvmArgs|OverrideMemory|MinMemAlloc|MaxMemAlloc)=/d' \
            "$src/instance.cfg"
          cat >>"$src/instance.cfg" <<'CFG'
          name=GT New Horizons ${version}
          AutomaticJava=false
          OverrideJavaLocation=true
          JavaPath=/etc/jdk21/bin/java
          OverrideJavaArgs=true
          JvmArgs="-XX:+UseZGC -XX:+ZGenerational -XX:ZUncommitDelay=60 -XX:SoftMaxHeapSize=5g"
          OverrideMemory=true
          MinMemAlloc=1024
          MaxMemAlloc=8192
          CFG

          cp -n "$src/gtnh_icon.png" "${prism}/icons/"
          mv "$src" "$dest"
          echo "gtnh-install: installed ${instance}"
        '';
      };
    in
    {
      xdg.desktopEntries.gtnh = {
        name = "GT New Horizons";
        genericName = "Minecraft modpack";
        exec = "prismlauncher --launch ${instance}";
        icon = "${prism}/icons/gtnh_icon.png";
        categories = [ "Game" ];
      };

      home.packages = [ gtnh-install ];

      # Started by a timer so a switch doesn't wait on the ~600 MB download
      systemd.user.timers.gtnh-install = {
        Unit.Description = "Install the GTNH Prism instance if missing";
        Timer.OnStartupSec = "2min";
        Install.WantedBy = [ "timers.target" ];
      };

      systemd.user.services.gtnh-install = {
        Unit = {
          Description = "Install the GTNH Prism instance if missing";
          ConditionPathExists = "!${prism}/instances/${instance}";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${gtnh-install}/bin/gtnh-install";
          Restart = "on-failure";
          RestartSec = 60;
        };
      };
    };
}
