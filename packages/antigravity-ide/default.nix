{
  lib,
  stdenv,
  requireFile,
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
  pname = "antigravity-ide";
  version = "1.107.0";

  # The tarball is not tracked in git (too large for a public repo).
  # Add it to the store once with:
  #   nix-store --add-fixed sha256 /path/to/antigravity-ide.tar.gz
  src = requireFile {
    name = "antigravity-ide.tar.gz";
    sha256 = "sha256-dHFjqjqK+6SzFvl8QLSnXKRzall2ikFs0eiB5z7DHvk=";
    url = "https://antigravity.google";
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

    mkdir -p $out/opt/antigravity-ide
    cp -r . $out/opt/antigravity-ide/

    # Create a bin directory and wrap the executable
    makeWrapper $out/opt/antigravity-ide/antigravity-ide $out/bin/antigravity-ide \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    # Install icon if present
    if [ -f "$out/opt/antigravity-ide/resources/app/resources/linux/code.png" ]; then
      mkdir -p $out/share/pixmaps
      cp $out/opt/antigravity-ide/resources/app/resources/linux/code.png $out/share/pixmaps/antigravity-ide.png
    fi

    # Create desktop entry
    mkdir -p $out/share/applications
    cat > $out/share/applications/antigravity-ide.desktop <<EOF
[Desktop Entry]
Name=Antigravity IDE
Exec=$out/bin/antigravity-ide %U
Type=Application
Categories=Development;TextEditor;
MimeType=text/plain;
EOF

    # Add icon to desktop entry if installed
    if [ -f "$out/share/pixmaps/antigravity-ide.png" ]; then
      echo "Icon=$out/share/pixmaps/antigravity-ide.png" >> $out/share/applications/antigravity-ide.desktop
    fi

    # Install completions if bundled
    if [ -d "$out/opt/antigravity-ide/resources/completions" ]; then
      mkdir -p $out/share/bash-completion/completions
      cp $out/opt/antigravity-ide/resources/completions/bash/antigravity-ide $out/share/bash-completion/completions/antigravity-ide 2>/dev/null || true
      mkdir -p $out/share/zsh/site-functions
      cp $out/opt/antigravity-ide/resources/completions/zsh/_antigravity-ide $out/share/zsh/site-functions/_antigravity-ide 2>/dev/null || true
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "Antigravity IDE Desktop Application";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
  };
}
