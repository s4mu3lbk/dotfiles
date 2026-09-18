{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  autoconf,
  automake,
  libtool,
  xxd,
  ncurses,
  libwebsockets,
  openssl,
  libcap,
  file,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "domterm";
  version = "3.2.0";

  src = fetchFromGitHub {
    owner = "PerBothner";
    repo = "DomTerm";
    tag = version;
    hash = "sha256-Nz3yrAU/mjan8G7llYJK/4+E6qfQ9MlkYP3ZvibSLC8=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    autoconf
    automake
    libtool
    xxd
    ncurses
  ];

  buildInputs = [
    libwebsockets
    openssl
    libcap
    file
    zlib
  ];

  configureFlags = [
    "--with-libwebsockets"
    "--without-java"
    "--without-java_websocket"
    "--without-qt"
    "--without-wry"
    "--without-webview"
    "--without-asciidoctor"
    "--without-libclipboard"
    "--without-xterm.js"
  ];

  meta = {
    description = "Terminal emulator/CONSOLE using web technologies";
    homepage = "https://domterm.org/";
    license = lib.licenses.gpl3Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "domterm";
  };
}
