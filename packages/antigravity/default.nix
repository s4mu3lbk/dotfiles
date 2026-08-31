{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
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
  expat,
  libxkbcommon,
  pciutils,
  at-spi2-atk,
  atk,
  systemd,
  libdrm,
  vulkan-loader,
  libxkbfile,
  webkitgtk_4_1,
  libsoup_3,
  curl,
  openssl,
}:
stdenv.mkDerivation rec {
  pname = "antigravity";
  version = "2.0.6";

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.6-5413878570549248/linux-x64/Antigravity.tar.gz";
    sha256 = "1iacwi4zpkdcp75hn0irrf4a7zaf1zafmc8f0ckprc29a59h87md";
  };

  nativeBuildInputs = [
    autoPatchelfHook
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
    expat
    libxkbcommon
    pciutils
    at-spi2-atk
    atk
    systemd
    libdrm
    vulkan-loader
    libxkbfile
    webkitgtk_4_1
    libsoup_3
    curl
    openssl
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/antigravity
    cp -r . $out/opt/antigravity/

    # Create a bin directory and wrap the executable
    makeWrapper $out/opt/antigravity/antigravity $out/bin/antigravity \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    # Install icon
    mkdir -p $out/share/icons/hicolor/512x512/apps
    cp ${./antigravity.png} $out/share/icons/hicolor/512x512/apps/antigravity.png

    # Create desktop entry
    mkdir -p $out/share/applications
    cat > $out/share/applications/antigravity.desktop <<EOF
[Desktop Entry]
Name=Antigravity
Exec=$out/bin/antigravity %U
Icon=antigravity
Type=Application
Categories=Development;TextEditor;
MimeType=text/plain;
EOF

    # Install completions if bundled
    if [ -d "$out/opt/antigravity/resources/completions" ]; then
      mkdir -p $out/share/bash-completion/completions
      cp $out/opt/antigravity/resources/completions/bash/antigravity $out/share/bash-completion/completions/antigravity 2>/dev/null || true
      mkdir -p $out/share/zsh/site-functions
      cp $out/opt/antigravity/resources/completions/zsh/_antigravity $out/share/zsh/site-functions/_antigravity 2>/dev/null || true
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "Antigravity Desktop Application";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };
}
