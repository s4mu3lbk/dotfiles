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
  alsa-lib,
  glib,
  nspr,
  dbus,
  cups,
  cairo,
  pango,
  libx11,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxcb,
  libxkbcommon,
  libdrm,
  expat,
  xz,
  mesa,
  libglvnd,
  libGL,
}:
stdenv.mkDerivation rec {
  pname = "balena-etcher";
  version = "2.1.6";

  src = fetchurl {
    url = "https://github.com/balena-io/etcher/releases/download/v${version}/balena-etcher_${version}_amd64.deb";
    hash = "sha256-K967Rsn3UKmr8RwYj/aaQFtKT+0RQzPWNMOz/lmmQFc=";
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
    alsa-lib # Common electron dependency
    glib # For libglib-2.0.so.0
    nspr # For libnspr4.so
    dbus # For libdbus-1.so.3
    cups # For libcups.so.2
    cairo # For libcairo.so.2
    pango # For libpango-1.0.so.0
    libx11 # For libX11.so.6
    libxcomposite # For libXcomposite.so.1
    libxcursor # For libXcursor.so.1
    libxdamage # For libXdamage.so.1
    libxext # For libXext.so.6
    libxfixes # For libXfixes.so.3
    libxi # For libXi.so.6
    libxrandr # For libXrandr.so.2
    libxrender # For libXrender.so.1
    libxcb # For libxcb.so.1
    libxkbcommon # For libxkbcommon.so.0
    libdrm # For libdrm.so.2
    expat # For libexpat.so.1
    xz # For liblzma.so.5
    mesa # for libgbm.so.1
    libglvnd # for libgbm.so.1
    libGL # for libgbm.so.1
  ];

  # etcher-util is a @yao-pkg/pkg binary that reads an appended payload from its
  # own file via a baked-in absolute offset. autoPatchelf's RPATH rewriting,
  # strip, and even a bare patchelf --set-interpreter all shift/relocate the
  # payload and break it ("Pkg: Error reading from file" / bootstrap
  # SyntaxError), which kills the sidecar and surfaces in the GUI as
  # "(0, h.requestMetadata) is not a function". So the binary is shipped
  # pristine (it runs via programs.nix-ld, enabled in system/core/nix.nix)
  # with only an LD_LIBRARY_PATH wrapper for its libstdc++ dependency.
  dontAutoPatchelf = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    # Extract the debian package. dpkg-deb --fsys-tarfile pipes an uncompressed
    # tar; --no-same-permissions avoids tar failing on the setuid chrome-sandbox.
    dpkg-deb --fsys-tarfile $src | tar --extract --no-same-permissions --file -

    # The main application files are in /usr/lib/balena-etcher
    mkdir -p $out/lib
    mv usr/lib/balena-etcher $out/lib/

    # Move the pristine pkg binary out of $out before auto-patchelfing the rest
    # (autoPatchelf scans hidden files too).
    mv $out/lib/balena-etcher/resources/etcher-util $TMPDIR/etcher-util-pristine
    autoPatchelf $out
    mv $TMPDIR/etcher-util-pristine \
       $out/lib/balena-etcher/resources/.etcher-util-unwrapped
    makeWrapper $out/lib/balena-etcher/resources/.etcher-util-unwrapped \
      $out/lib/balena-etcher/resources/etcher-util \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [stdenv.cc.cc.lib]}"

    # Create a bin directory and wrap the executable to ensure all libraries are found.
    makeWrapper $out/lib/balena-etcher/balena-etcher $out/bin/balena-etcher \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}" \
      --add-flags "--ozone-platform-hint=auto"

    # Copy the desktop file and icon (Exec=balena-etcher and Icon=balena-etcher
    # already match the wrapped binary and the pixmap).
    mkdir -p $out/share
    mv usr/share/applications $out/share/
    mv usr/share/pixmaps $out/share/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Flash OS images to SD cards and USB drives, safely and easily";
    homepage = "https://github.com/balena-io/etcher";
    license = licenses.asl20;
    maintainers = [];
    platforms = ["x86_64-linux"];
    mainProgram = "balena-etcher";
  };
}
