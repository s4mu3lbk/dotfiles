{ pkgs, lib, config, ... }: {
  options.kde = { enable = lib.mkEnableOption "KDE Plasma"; };

  config = lib.mkIf config.kde.enable {
    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.kate
      kdePackages.plasma-browser-integration
      kdePackages.filelight
      kdePackages.kcalc
    ];

    programs.kdeconnect.enable = true;
  };
}
