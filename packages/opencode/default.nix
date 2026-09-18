{
  lib,
  stdenv,
  fetchurl,
  patchelf,
  glibc,
}:

stdenv.mkDerivation rec {
  pname = "opencode";
  version = "1.18.31";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    hash = "sha256-6TEr517YA7dBX8Kuq9ofT+k4kSo5Zzdi3Aw4wOEeveQ=";
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
