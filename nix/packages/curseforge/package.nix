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
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libxcb,
  libxkbfile,
  libxshmfence,
  icu,
  openssl,
  zlib,
  krb5,
}:

let
  source = lib.importJSON ./source.json;
in
stdenv.mkDerivation {
  pname = "curseforge";
  inherit (source) version;

  src = fetchurl { inherit (source) url hash; };

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
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxcb
    libxkbfile
    libxshmfence
    # Curse.Agent.Host, the bundled .NET agent
    icu
    openssl
    zlib
    krb5
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
    cp -r opt/CurseForge $out/opt/curseforge
    cp -r usr/share/applications $out/share/
    cp -r usr/share/icons $out/share/

    substituteInPlace $out/share/applications/curseforge.desktop \
      --replace-fail /opt/CurseForge/curseforge $out/bin/curseforge

    runHook postInstall
  '';

  # gappsWrapperArgs is filled by a preFixupPhases hook, so it is still
  # empty during installPhase
  preFixup = ''
    # No setuid helper in the store; Electron falls back to the
    # user-namespace sandbox when chrome-sandbox is absent
    rm -f $out/opt/curseforge/chrome-sandbox

    makeWrapper $out/opt/curseforge/curseforge $out/bin/curseforge \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          libglvnd
          # .NET dlopens these instead of linking them
          icu
          openssl
          krb5
        ]
      } \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
  '';

  meta = {
    description = "CurseForge - mod manager for Minecraft, WoW and other games";
    homepage = "https://curseforge.overwolf.com";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "curseforge";
  };
}
