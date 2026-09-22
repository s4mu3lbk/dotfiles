{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  gtk3,
  libnotify,
  nss,
  libxscrnsaver,
  libxtst,
  xdg-utils,
  at-spi2-core,
  libuuid,
  libsecret,
  libappindicator-gtk3,
  alsa-lib,
  glib,
  nspr,
  dbus,
  cups,
  cairo,
  pango,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  mesa,
  libglvnd,
  libGL,
  libdrm,
  libxkbcommon,
  wayland,
}:

stdenv.mkDerivation rec {
  pname = "opencode-desktop";
  version = "2.0.11";

  src = fetchurl {
    url = "https://opencode.ai/download/stable/linux-x64-deb";
    hash = "sha256-y98LLRZI+nJacZc8Hlp6QNnvu0lfmEdOzd2mhqi/dC8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  dontUnpack = true;

  buildInputs = [
    gtk3
    libnotify
    nss
    libxscrnsaver
    libxtst
    xdg-utils
    at-spi2-core
    libuuid
    libsecret
    libappindicator-gtk3
    alsa-lib
    glib
    nspr
    dbus
    cups
    cairo
    pango
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    mesa
    libglvnd
    libGL
    libdrm
    libxkbcommon
    wayland
  ];

  installPhase = ''
    runHook preInstall

    # Extract the debian package
    dpkg -x $src .

    # Remove musl binaries - we're on glibc
    find opt/OpenCode/resources/app.asar.unpacked -path "*musl*" -type f -delete
    find opt/OpenCode/resources/app.asar.unpacked -name "*.musl.*" -type f -delete

    # The main application files are in /opt
    mkdir -p $out/opt
    mv opt/OpenCode $out/opt/

    # Create a bin directory and wrap the executable
    # v1.17.3 renamed the binary to ai.opencode.desktop
    makeWrapper $out/opt/OpenCode/ai.opencode.desktop $out/bin/ai.opencode.desktop \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --add-flags "--ozone-platform-hint=auto"

    # Create backward-compatible symlink
    ln -s $out/bin/ai.opencode.desktop $out/bin/opencode-desktop

    # Copy the desktop file and icons
    mkdir -p $out/share
    mv usr/share/applications $out/share/
    mv usr/share/icons $out/share/

    # Update the Exec key in the .desktop files
    substituteInPlace $out/share/applications/opencode-desktop.desktop \
      --replace "/opt/OpenCode/ai.opencode.desktop" "$out/bin/ai.opencode.desktop"

    substituteInPlace $out/share/applications/ai.opencode.desktop.desktop \
      --replace "/opt/OpenCode/ai.opencode.desktop" "$out/bin/ai.opencode.desktop"

    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode Desktop - AI coding assistant";
    homepage = "https://opencode.ai";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode-desktop";
  };
}
