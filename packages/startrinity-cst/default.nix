{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  openssl,
  openssl_1_1,
  krb5,
  lttng-ust,
  zlib,
}:

let
  # The bundled .NET 5 crypto shim predates OpenSSL 3 and only probes
  # libssl.so.1.1 sonames. OpenSSL 1.1.1 is EOL (2023-09) — drop the
  # insecure marker; it is only exposed to this legacy binary.
  openssl11 = openssl_1_1.overrideAttrs (old: {
    meta = old.meta // {
      insecure = false;
      knownVulnerabilities = [ ];
    };
  });
in
stdenv.mkDerivation rec {
  pname = "startrinity-cst";
  # Upstream ships an unversioned "latest" tarball; project is unmaintained
  # since 2020 (page says "The project is stopped"). Version taken from the
  # tarball's HTTP Last-Modified date.
  version = "2023.05.24";

  src = fetchurl {
    url = "https://startrinity.com/InternetQuality/startrinity_cst_linux_x64.tar.gz";
    hash = "sha256-GVP2+1A+FLOsFO4x6MLmHQ8NJ4RBd3Y+VBjQKguOPQ0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # libcoreclrtraceptprovider.so wants the old LTTng soname (2.12 era);
  # tracing is optional, safe to leave unresolved (same as nixpkgs' dotnet)
  autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];

  # Self-contained .NET 5 app (invariant globalization, no ICU needed);
  # autoPatchelfHook resolves the native deps
  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    openssl
    krb5
    lttng-ust
    zlib
  ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/startrinity-cst $out/bin
    cp -r . $out/share/startrinity-cst
    chmod +x $out/share/startrinity-cst/CST.CrossPlatform

    # .NET 5 dlopens libssl/libcrypto/libgssapi_krb5 by soname at runtime;
    # openssl11 first so the shim finds libssl.so.1.1
    makeWrapper $out/share/startrinity-cst/CST.CrossPlatform $out/bin/startrinity-cst \
      --prefix LD_LIBRARY_PATH : "${lib.getLib openssl11}/lib:${lib.makeLibraryPath buildInputs}"

    runHook postInstall
  '';

  meta = {
    description = "StarTrinity Continuous Speed Test - long-term internet bandwidth/stability monitor (CLI + web UI)";
    homepage = "https://startrinity.com/InternetQuality/ContinuousBandwidthTester.aspx";
    license = lib.licenses.unfree; # free for non-commercial use
    platforms = [ "x86_64-linux" ];
    mainProgram = "startrinity-cst";
  };
}
