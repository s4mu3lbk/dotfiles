{
  lib,
  appimageTools,
  fetchurl,
  writeText,
  readline,
  stdenv,
}: let
  pname = "pixelflasher";
  version = "9.2.1.0";

  src = fetchurl {
    url = "https://github.com/badabing2005/PixelFlasher/releases/download/v${version}/PixelFlasher-x86_64.AppImage";
    hash = "sha256-bAr1qCJyeHUEz9HtuvlvyXb9WTELcoBJNdqMB2DmFHU=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};

  fontsConf = writeText "pixelflasher-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <dir>/usr/share/fonts</dir>
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
      <match target="pattern">
        <test qual="any" name="family"><string>Adwaita Sans</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>DejaVu Sans</string></edit>
      </match>
      <match target="pattern">
        <test qual="any" name="family"><string>Cantarell</string></test>
        <edit name="family" mode="prepend" binding="strong"><string>DejaVu Sans</string></edit>
      </match>
    </fontconfig>
  '';
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: with pkgs; [
      dejavu_fonts
      liberation_ttf
    ];

    profile = ''
      export FONTCONFIG_FILE=${fontsConf}
      # The PyInstaller bundle ships old Ubuntu libs that shadow the ones nix
      # binaries need when PixelFlasher spawns subprocesses (/bin/sh, adb,
      # fastboot): libreadline lacks rl_completion_rewrite_hook, libstdc++
      # lacks GLIBCXX_3.4.32/CXXABI_1.3.15. Preload the nixpkgs versions.
      export LD_PRELOAD=${lib.concatStringsSep ":" [
        "${readline}/lib/libreadline.so.8"
        "${stdenv.cc.cc.lib}/lib/libstdc++.so.6"
        "${stdenv.cc.cc.lib}/lib/libgcc_s.so.1"
      ]}''${LD_PRELOAD:+:$LD_PRELOAD}
    '';

    # PixelFlasher detects NixOS via /etc/NIXOS to auto-locate adb/fastboot
    # in /run/current-system/sw/bin (the bwrap sandbox hides it by default).
    extraBwrapArgs = [
      "--ro-bind-try"
      "/etc/NIXOS"
      "/etc/NIXOS"
    ];

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/PixelFlasher.desktop $out/share/applications/pixelflasher.desktop
      substituteInPlace $out/share/applications/pixelflasher.desktop \
        --replace-fail "Exec=usr/bin/PixelFlasher" "Exec=pixelflasher"
      install -Dm444 ${appimageContents}/pixelflasher.png $out/share/pixmaps/pixelflasher.png
    '';

    meta = with lib; {
      description = "Pixel phone flashing GUI utility with features";
      homepage = "https://github.com/badabing2005/PixelFlasher";
      license = licenses.gpl3Plus;
      maintainers = [];
      platforms = ["x86_64-linux"];
      mainProgram = "pixelflasher";
    };
  }
