{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  gtk3,
  libnotify,
  nss,
  libXScrnSaver,
  libXtst,
  xdg-utils,
  at-spi2-atk,
  util-linux,
  libsecret,
  libappindicator-gtk3,
  alsa-lib,
  mesa,
  libglvnd,
  openssl,
}:

stdenv.mkDerivation {
  pname = "curseforge";
  version = "1.322.0";

  src = fetchurl {
    url = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.deb";
    hash = "sha256-3N8LXroBKdLji4Eeal9NudOyUn76kfNqegXxqpuOgU8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    libnotify
    nss
    libXScrnSaver
    libXtst
    at-spi2-atk
    util-linux
    libsecret
    libappindicator-gtk3
    alsa-lib
    mesa
    libglvnd
  ];

  dontWrapGApps = true;

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/CurseForge
    cp -r opt/CurseForge/* $out/opt/CurseForge/

    mkdir -p $out/share/applications
    cp usr/share/applications/curseforge.desktop $out/share/applications/

    cp -r usr/share/icons $out/share/

    substituteInPlace $out/share/applications/curseforge.desktop \
      --replace-fail "/opt/CurseForge/curseforge" "$out/bin/curseforge"

    makeWrapper $out/opt/CurseForge/curseforge $out/bin/curseforge \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ mesa libglvnd openssl ]} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"

    runHook postInstall
  '';

  meta = {
    description = "The CurseForge Electron app for managing game mods";
    homepage = "https://curseforge.overwolf.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "curseforge";
  };
}
