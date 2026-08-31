{ pkgs, ... }:
{
  services.gammastep = {
    enable = false;
    provider = "geoclue2";
    temperature = {
      day = 5700;
      night = 3500;
    };
    settings = {
      general = {
        brightness-day = "1.0";
        brightness-night = "1.0";
      };
    };
  };
}
