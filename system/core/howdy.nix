# Howdy: facial authentication for Linux
{pkgs, ...}: {
  services.howdy = {
    enable = true;
    package = pkgs.howdy;
    control = "sufficient";
    settings = {
      video.device_path = "/dev/video2"; # Test video0
    };
  };

  # Enable howdy for polkit
  security.pam.services.polkit-1.howdy.enable = true;

  # Polkit sandboxing blocks howdy from accessing the camera.
  # We need to disable PrivateDevices to allow it.
  systemd.services."polkit-agent-helper@" = {
    serviceConfig = {
      PrivateDevices = false;
      DeviceAllow = [
        "char-video rw"
      ];
      # Some users report ProtectHome=read-only is needed for polkit-agent-helper
      ProtectHome = "read-only";
    };
  };
}
