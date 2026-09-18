{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  unzip,
  glibc,
  gcc-unwrapped,
}:

stdenv.mkDerivation rec {
  pname = "kimi-cli";
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/MoonshotAI/kimi-code/releases/download/%40moonshot-ai/kimi-code%40${version}/kimi-code-linux-x64.zip";
    hash = "sha256-fRMaPhc/VtkqUufGv4YhSipuNRbyuVE2BWf4JIvWK6Y=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];

  buildInputs = [
    glibc
    gcc-unwrapped
  ];

  dontStrip = true;

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp kimi $out/bin/kimi
    chmod +x $out/bin/kimi
    ln -s $out/bin/kimi $out/bin/kimi-cli
    runHook postInstall
  '';

  meta = with lib; {
    description = "Kimi Code CLI — The Starting Point for Next-Gen Agents by Moonshot AI";
    homepage = "https://github.com/MoonshotAI/kimi-code";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "kimi";
  };
}
