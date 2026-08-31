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
}:
stdenv.mkDerivation rec {
  pname = "binance";
  version = "2.1.0";

  src = fetchurl {
    url = "https://github.com/binance/desktop/releases/download/v${version}/binance-${version}-amd64-linux.deb";
    hash = "sha256-iwXdvrFfDUDpVU0no3uwaVrAHaP5arVibaLZ+4zOVgw=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

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
    alsa-lib # Common electron dependency
    glib # For libglib-2.0.so.0
    nspr # For libnspr4.so
    dbus # For libdbus-1.so.3
    cups # For libcups.so.2
    cairo # For libcairo.so.2
    pango # For libpango-1.0.so.0
    libx11 # For libx11.so.6
    libxcomposite # For libxcomposite.so.1
    libxdamage # For libxdamage.so.1
    libxext # For libxext.so.6
    libxfixes # For libxfixes.so.3
    libxrandr # For libxrandr.so.2
    mesa # for libgbm.so.1
    libglvnd # for libgbm.so.1
    libGL # for libgbm.so.1
  ];

  # The .deb contains files with non-standard permissions that trip up the default fixupPhase.
  # autoPatchelfHook will still run.

  installPhase = ''
    runHook preInstall

    # Extract the debian package
    dpkg -x $src .

    # The main application files are in /opt
    mkdir -p $out/opt
    mv opt/Binance $out/opt/

    # Create a bin directory and wrap the executable to ensure all libraries are found.
    makeWrapper $out/opt/Binance/binance $out/bin/binance \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --add-flags "--ozone-platform-hint=auto"

    # Copy the desktop file and icons
    mkdir -p $out/share
    mv usr/share/* $out/share/

    # Update the Exec key in the .desktop file to point to the executable in the Nix store.
    # This ensures that desktop environments can find and launch the application.
    substituteInPlace $out/share/applications/binance.desktop \
      --replace "/opt/Binance/binance" "$out/bin/binance"

    # Also replace the icon path to be absolute
    substituteInPlace $out/share/applications/binance.desktop \
      --replace "Icon=binance" "Icon=$out/share/icons/hicolor/512x512/apps/binance.png"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Desktop application for the Binance crypto exchange";
    homepage = "https://www.binance.com/";
    license = licenses.unfree; # The license is proprietary
    maintainers = [];
    platforms = ["x86_64-linux"];
  };
}

