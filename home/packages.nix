{ pkgs, inputs, ... }:
let
  # Removed from nixpkgs (upstream archived); vendored from the last commit
  fasd = pkgs.stdenvNoCC.mkDerivation {
    pname = "fasd";
    version = "1.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "clvv";
      repo = "fasd";
      rev = "90b531a5daaa545c74c7d98974b54cbdb92659fc";
      hash = "sha256-ITDZH7K+PvSlj6eX8lR+6PqWxSHs/L74vs3GgWHFQkQ=";
    };
    installPhase = ''
      runHook preInstall
      install -Dm755 fasd $out/bin/fasd
      install -Dm644 fasd.1 $out/share/man/man1/fasd.1
      runHook postInstall
    '';
  };
in
{
  home.packages = pkgs.lib.flatten (
    with pkgs;
    [
      (import ../scripts pkgs).lorem
      (import ../scripts pkgs).update-package
      (mpv.override {
        scripts = [ mpvScripts.mpris ];
        # Enable hardware acceleration in mpv
        extraMakeWrapperArgs = [
          "--set"
          "LIBVA_DRIVER_NAME"
          "iHD"
        ];
      })
      neovide
      entr
      jq.bin
      tldr
      tor-browser
      bruno
      # antigravity
      # antigravity-ide
      bashInteractive
      fastfetch
      ghostty
      # firefox-devedition
      google-chrome
      tmuxai
      bitwarden-cli
      bitwarden-desktop
      binance
      tradingview
      slack
      # Additional media tools for testing
      vlc # Alternative media player with broad codec support
      # gnome-secrets
      fragments
      figma-linux
      # yabridge
      # yabridgectl
      # wine-staging
      nodejs
      httpie
      btop
      fasd
      bat
      eza
      lsd
      fd
      ripgrep
      fzf
      lazydocker
      lazygit
      carbonyl
      ngrok
      jiratui
      kimi-cli
      opencode
      opencode-desktop
      # Kimi Work desktop app — local Linux port living outside nixpkgs
      # (flake input `kimi-work`; commit changes there, then refresh the lock)
      inputs.kimi-work.packages.${pkgs.stdenv.hostPlatform.system}.kimi-work
      pixelflasher
      etcher
      startrinity-cst

      # SDR (HackRF)
      gqrx
      sdrpp
      sdrangel
      inspectrum
      (gnuradio.override {
        extraPackages = [ gnuradioPackages.osmosdr ]; # gr-osmosdr built with HackRF support
      })
      claude-code
      statix
      deadnix
      domterm
    ]
  );
}
