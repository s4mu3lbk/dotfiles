{
  pkgs,
  lib,
  config,
  ...
}: {
  options.cosmic = {
    enable = lib.mkEnableOption "Cosmic Desktop";
    monitor.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the COSMIC System Monitor.";
    };
  };

  config = lib.mkIf config.cosmic.enable {
    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
      config.cosmic = {
        default = [ "cosmic" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = "cosmic";
        "org.freedesktop.impl.portal.Screenshot" = "cosmic";
        "org.freedesktop.impl.portal.Settings" = "gtk";
      };
    };

    programs.kdeconnect.enable = true;
    environment.sessionVariables = {
      COSMIC_DATA_CONTROL_ENABLED = "1";
      # Additional Wayland and media environment variables
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      # Ensure proper VA-API integration
      LIBVA_DRIVER_NAME = "iHD";
      GST_VAAPI_ALL_DRIVERS = 1;
      # COSMIC compositor stability settings
      COSMIC_DISABLE_DIRECT_SCANOUT = "1"; # Disable direct scanout for stability
      COSMIC_FORCE_SOFTWARE_CURSOR = "0"; # Keep hardware cursor enabled
    };
    environment.cosmic.excludePackages = with pkgs; [cosmic-term];

    environment.systemPackages = lib.mkIf config.cosmic.monitor.enable (with pkgs; [
      cosmic-monitor
    ]);

    services.system76-scheduler.enable = true;
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
    services.geoclue2.enable = true;
  };
}
