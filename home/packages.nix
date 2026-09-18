{ pkgs, ... }: {
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
      antigravity
      antigravity-ide
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
      pixelflasher
      etcher
      startrinity-cst

      # SDR (HackRF)
      gqrx
      sdrpp
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
