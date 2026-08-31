{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  unzip,
  nss,
  nspr,
  expat,
  alsa-lib,
  libdrm,
  libxkbcommon,
  mesa,
  fontconfig,
  freetype,
  glib,
  gtk3,
  cairo,
  pango,
  gdk-pixbuf,
  at-spi2-atk,
  dbus,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  systemd,
}:
stdenv.mkDerivation rec {
  pname = "carbonyl";
  version = "0.0.3";

  src = fetchurl {
    url = "https://github.com/fathyb/carbonyl/releases/download/v${version}/carbonyl.linux-amd64.zip";
    sha256 = "1lksxjhsdbiyz66jnhhhm12j7f856x143qsfzdrzfcmv57m05aa6";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    unzip
  ];

  buildInputs = [
    nss
    nspr
    expat
    alsa-lib
    libdrm
    libxkbcommon
    mesa
    fontconfig
    freetype
    glib
    gtk3
    cairo
    pango
    gdk-pixbuf
    at-spi2-atk
    dbus
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    systemd
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/carbonyl
    cp -r * $out/lib/carbonyl/
    
    makeWrapper $out/lib/carbonyl/carbonyl $out/bin/carbonyl \
      --add-flags "--no-sandbox --no-zygote --disable-gpu --in-process-gpu"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Chromium running in your terminal";
    homepage = "https://github.com/fathyb/carbonyl";
    license = licenses.mit;
    maintainers = [];
    platforms = ["x86_64-linux"];
  };
}