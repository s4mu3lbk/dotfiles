{ pkgs, ... }: {
  home = {
    sessionVariables = {
      BROWSER = "vivaldi";
      # QT_QPA_PLATFORM = "xcb";
      # Prefer Wayland for Chromium/Vivaldi wrappers on NixOS (adds Ozone flags)
      NIXOS_OZONE_WL = "1";
      # Force VA-API and other GPU flags for Chromium-based browsers (incl. Vivaldi)
      # Optimized for stability with fullscreen video
      CHROMIUM_FLAGS = builtins.concatStringsSep " " [
        "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks,PlatformHEVCDecoderSupport,WebRTCPipeWireCapturer"
        "--ozone-platform-hint=wayland"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--use-gl=egl"
        "--enable-gpu-rasterization"
        "--enable-oop-rasterization"
        "--disable-software-rasterizer"
        # Stability improvements for fullscreen video
        "--disable-background-timer-throttling"
        "--disable-backgrounding-occluded-windows"
        "--disable-renderer-backgrounding"
        "--disable-gpu-sandbox"           # Can help with GPU process crashes
        "--max_old_space_size=4096"       # Increase memory limit
        "--disable-dev-shm-usage"         # Reduce shared memory usage
        "--disable-extensions-on-chrome-urls"
        # Fallback options (comment out hardware overlays if issues persist)
        "--enable-hardware-overlays"
      ];

      # Alternative minimal flags for troubleshooting
      CHROMIUM_FLAGS_MINIMAL = builtins.concatStringsSep " " [
        "--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer"
        "--ozone-platform-hint=wayland"
        "--disable-gpu-sandbox"
        "--disable-dev-shm-usage"
      ];
      # Ensure Intel VA-API driver is picked (Zenbook iGPU)
      LIBVA_DRIVER_NAME = "iHD";
      # Additional media environment variables
      GST_VAAPI_ALL_DRIVERS = "1";
    };
  };

  programs.qutebrowser = {
    enable = true;
    settings = {
      window.hide_decoration = true;
      colors.webpage.preferred_color_scheme = "dark";
      auto_save.session = true;
      qt.highdpi = true;
    };
  };

  programs.vivaldi = {
    enable = true;
    package = pkgs.vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = true;
      # Additional codec support
      commandLineArgs = [
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,VaapiIgnoreDriverChecks,WebRTCPipeWireCapturer"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        "--enable-accelerated-video-decode"
        "--enable-accelerated-video-encode"
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
      ];
    };
  };

  programs.firefox = {
    enable = true;
    # ESR tends to be the most compatible with e‑services; vanilla is fine too
    package = pkgs.firefox-esr;
    nativeMessagingHosts = [ ];
    # Make PKCS#11 available to Firefox (via p11-kit)
    policies.SecurityDevices.p11-kit-proxy =
      "${pkgs.p11-kit}/lib/p11-kit-proxy.so";
    profiles.default = {
      name = "Default";
      settings = {
        "browser.tabs.loadInBackground" = true;
        "widget.gtk.rounded-bottom-corners.enabled" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "svg.context-properties.content.enabled" = true;
        "gnomeTheme.hideSingleTab" = true;
        "gnomeTheme.bookmarksToolbarUnderTabs" = true;
        "gnomeTheme.normalWidthTabs" = false;
        "gnomeTheme.tabsAsHeaderbar" = false;
      };
      userChrome = ''
        @import "firefox-gnome-theme/userChrome.css";
      '';
      userContent = ''
        @import "firefox-gnome-theme/userContent.css";
      '';
    };
  };
}
