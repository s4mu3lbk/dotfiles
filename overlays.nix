{ inputs }: self: super: {
  binance = super.callPackage ./packages/binance { };
  tradingview = super.callPackage ./packages/tradingview { };
  carbonyl = super.callPackage ./packages/carbonyl { };
  # antigravity = super.callPackage ./packages/antigravity { };
  # antigravity-ide = super.callPackage ./packages/antigravity-ide { };
  windscribe = super.callPackage ./packages/windscribe { };
  kimi-cli = super.callPackage ./packages/kimi-cli { };
  opencode = super.callPackage ./packages/opencode { };
  opencode-desktop = super.callPackage ./packages/opencode-desktop { };
  pixelflasher = super.callPackage ./packages/pixelflasher { };
  etcher = super.callPackage ./packages/etcher { };
  startrinity-cst = super.callPackage ./packages/startrinity-cst { };
  domterm = super.callPackage ./packages/domterm { };

  # SDRangel 7.27.1 (Qt 6.11) SIGSEGVs a few seconds after startup under Wayland:
  # crash in QProgressDialog::setLabelText while LoadConfigurationFSM loads device
  # set settings (COSMIC sets QT_QPA_PLATFORM=wayland;xcb, so Qt picks wayland).
  # Forcing the xcb (XWayland) platform plugin works around it.
  # --unset QT_XCB_GL_INTEGRATION: home.nix sets it to "none" globally (kde-connect
  # workaround), which would leave SDRangel's QOpenGLWidgets (spectrum, waterfall)
  # unable to create any GL context under xcb. GLX is available via XWayland.
  sdrangel =
    let
      upstream = super.sdrangel;
    in
    super.runCommand "sdrangel-xcb" { nativeBuildInputs = [ super.makeWrapper ]; } ''
      mkdir -p $out/bin
      ln -s ${upstream}/lib $out/lib
      ln -s ${upstream}/share $out/share
      for b in ${upstream}/bin/*; do
        name="$(basename "$b")"
        if [ "$name" = "sdrangel" ]; then
          makeWrapper "$b" "$out/bin/$name" --set QT_QPA_PLATFORM xcb --unset QT_XCB_GL_INTEGRATION
        else
          ln -s "$b" "$out/bin/$name"
        fi
      done
    '';

  # Local cosmic-comp with wlr-gamma-control-unstable-v1 support (night light / color shift).
  # Source: /home/samuel/Projects/self/cosmic-epoch/cosmic-comp (master + gamma patch)
  # NOTE: master's Cargo.lock has drifted from the epoch-1.8.0 tag, hence the vendored
  #       deps override (cargoHash is fixed at buildRustPackage call time, so we replace
  #       cargoDeps instead).
  # Remember: commit changes in that repo, then `nix flake lock --update-input cosmic-comp-patch`.
  cosmic-comp = super.cosmic-comp.overrideAttrs (oldAttrs: {
    version = "1.8.0-gamma.1";
    src = inputs.cosmic-comp-patch;
    cargoDeps = super.rustPlatform.fetchCargoVendor {
      name = "cosmic-comp-1.8.0-gamma.1-vendor";
      src = inputs.cosmic-comp-patch;
      hash = "sha256-WTpJuj3Xz9hHLj+kuhys0Fr8FmosAuXpbtNSK3Y5twU=";
    };
  });

  # Pin qdigidoc to latest upstream release (nixpkgs lags behind open-eid/DigiDoc4-Client)
  # libdigidocpp 4.5.0 is required by qdigidoc 4.11.0
  libdigidocpp = super.libdigidocpp.overrideAttrs (oldAttrs: rec {
    version = "4.5.0";
    src = super.fetchFromGitHub {
      owner = "open-eid";
      repo = "libdigidocpp";
      tag = "v${version}";
      hash = "sha256-/RCRYF3G7/0J6oHT4mfapI4tlYLdWlQ2HTVqJGuDm3A=";
    };
  });

  qdigidoc =
    let
      # Estonian TSL, bundled like nixpkgs' vendored eu-lotl.xml (living document; refresh hash when it rotates)
      estonian-tsl = super.fetchurl {
        url = "https://sr.riik.ee/tsl/estonian-tsl.xml";
        hash = "sha256-xre4cvrcr90krXcve2ZJxch+OqJ+pElScn6nPSxDWRg=";
      };
    in
    super.qdigidoc.overrideAttrs (
      oldAttrs:
      let
        # Reuse nixpkgs' vendored eu-lotl.xml via the -DTSL_URL=file:// cmakeFlag
        tslFlag = builtins.head (
          builtins.filter (f: super.lib.hasPrefix "-DTSL_URL=" f) oldAttrs.cmakeFlags
        );
        eu-lotl = builtins.substring (builtins.stringLength "-DTSL_URL=file://") (-1) tslFlag;
      in
      rec {
        version = "4.11.0";
        src = super.fetchFromGitHub {
          owner = "open-eid";
          repo = "DigiDoc4-Client";
          tag = "v${version}";
          hash = "sha256-IPTI96gOLoZVOeZkWsxSIP4MkkFUGD+Vkgj3f0vJ3MA=";
          fetchSubmodules = true;
        };
        # 4.11.0 downloads the Estonian TSL during the build; place both TSL lists
        # in the source tree instead so CMake uses them and skips the download
        # (no network in the Nix sandbox). CMake derives the expected filename from
        # TSL_URL, so drop nixpkgs' store-path TSL_URL flag — the upstream default
        # URL yields the expected plain "eu-lotl.xml" name and is never fetched.
        cmakeFlags = builtins.filter (f: !(super.lib.hasPrefix "-DTSL_URL=" f)) oldAttrs.cmakeFlags;
        postPatch = (oldAttrs.postPatch or "") + ''
          cp ${eu-lotl} client/eu-lotl.xml
          cp ${estonian-tsl} client/EE.xml
        '';
      }
    );

  python3 = super.python3.override {
    packageOverrides = pyself: pysuper: {
      # nixpkgs' 0001-use-importlib-resources.patch already migrates
      # face-recognition-models off pkg_resources; no override needed.
      opencv4Full = pysuper.opencv4Full.override { enableVtk = false; };
    };
  };

  gdal = super.gdal.overrideAttrs (oldAttrs: {
    disabledTests = (oldAttrs.disabledTests or [ ]) ++ [ "test_zarr_read_simple_sharding" ];
  });
}
