{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  libdrm,
  libglvnd,
  libnotify,
  libpulseaudio,
  libsecret,
  libuuid,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  xdg-utils,
  xorg,
}:

stdenv.mkDerivation {
  pname = "irealpro";
  version = "2026.7.5";

  src = fetchurl {
    url = "https://linux.irealpro.com/irealpro_latest_amd64.deb";
    hash = "sha256-GxdY0m0vg/0eJ+AFGmWTodDsJ91kc1fjenF0cEVA0F8=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups.lib
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
    libdrm
    libglvnd
    libnotify
    libpulseaudio
    libsecret
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxkbfile or null
    xorg.libxshmfence
  ];

  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin $out/share
    cp -r opt/iRealPro $out/opt/irealpro
    cp -r usr/share/applications $out/share/
    cp -r usr/share/icons $out/share/
    cp -r usr/share/metainfo $out/share/

    substituteInPlace $out/share/applications/irealpro.desktop \
      --replace-fail /opt/iRealPro/irealpro $out/bin/irealpro

    makeWrapper $out/opt/irealpro/irealpro $out/bin/irealpro \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libglvnd ]} \
      --add-flags "--no-sandbox"

    runHook postInstall
  '';

  meta = {
    description = "iReal Pro - music practice tool with chord charts and backing tracks";
    homepage = "https://www.irealpro.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "irealpro";
  };
}
