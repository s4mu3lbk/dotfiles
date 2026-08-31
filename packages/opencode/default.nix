{
  lib,
  stdenv,
  fetchurl,
  patchelf,
  glibc,
}:

stdenv.mkDerivation rec {
  pname = "opencode";
  version = "1.18.25";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    hash = "sha256-WKNymm80Mt1tKRf8xKlJeIiRoDWBhkatSA4SyUf1bng=";
  };

  nativeBuildInputs = [
    patchelf
  ];

  sourceRoot = ".";

  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp opencode $out/bin/opencode
    chmod +x $out/bin/opencode
    runHook postInstall
  '';

  postFixup = ''
    patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" $out/bin/opencode
  '';

  meta = with lib; {
    description = "OpenCode - AI coding assistant CLI";
    homepage = "https://opencode.ai";
    license = licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "opencode";
  };
}
