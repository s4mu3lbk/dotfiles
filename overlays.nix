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
