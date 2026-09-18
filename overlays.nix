self: super: {
  binance = super.callPackage ./packages/binance { };
  tradingview = super.callPackage ./packages/tradingview { };
  carbonyl = super.callPackage ./packages/carbonyl { };
  antigravity = super.callPackage ./packages/antigravity { };
  antigravity-ide = super.callPackage ./packages/antigravity-ide { };
  windscribe = super.callPackage ./packages/windscribe { };
  kimi-cli = super.callPackage ./packages/kimi-cli { };
  opencode = super.callPackage ./packages/opencode { };
  opencode-desktop = super.callPackage ./packages/opencode-desktop { };
  pixelflasher = super.callPackage ./packages/pixelflasher { };
  etcher = super.callPackage ./packages/etcher { };
  startrinity-cst = super.callPackage ./packages/startrinity-cst { };
  domterm = super.callPackage ./packages/domterm { };

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
    super.qdigidoc.overrideAttrs (oldAttrs:
      let
        # Reuse nixpkgs' vendored eu-lotl.xml via the -DTSL_URL=file:// cmakeFlag
        tslFlag = builtins.head (builtins.filter (f: super.lib.hasPrefix "-DTSL_URL=" f) oldAttrs.cmakeFlags);
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
      });

  python3 = super.python3.override {
    packageOverrides = pyself: pysuper: {
      face-recognition-models = pysuper.face-recognition-models.overridePythonAttrs (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace face_recognition_models/__init__.py \
            --replace-fail 'from pkg_resources import resource_filename' 'from importlib.resources import files' \
            --replace-fail 'return resource_filename(__name__, "models/shape_predictor_68_face_landmarks.dat")' 'return str(files(__name__).joinpath("models/shape_predictor_68_face_landmarks.dat"))' \
            --replace-fail 'return resource_filename(__name__, "models/shape_predictor_5_face_landmarks.dat")' 'return str(files(__name__).joinpath("models/shape_predictor_5_face_landmarks.dat"))' \
            --replace-fail 'return resource_filename(__name__, "models/dlib_face_recognition_resnet_model_v1.dat")' 'return str(files(__name__).joinpath("models/dlib_face_recognition_resnet_model_v1.dat"))' \
            --replace-fail 'return resource_filename(__name__, "models/mmod_human_face_detector.dat")' 'return str(files(__name__).joinpath("models/mmod_human_face_detector.dat"))'
        '';
      });
      opencv4Full = pysuper.opencv4Full.override { enableVtk = false; };
    };
  };

  gdal = super.gdal.overrideAttrs (oldAttrs: {
    disabledTests = (oldAttrs.disabledTests or [ ]) ++ [ "test_zarr_read_simple_sharding" ];
  });
}
