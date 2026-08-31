# Virtualisation: podman, docker, libvirtd, waydroid
{lib, ...}: {
  programs.virt-manager.enable = true;

  virtualisation = {
    waydroid.enable = false;
    podman.enable = true;
    docker = {
      enable = true;
      daemon.settings = {
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
        };
      };
    };
    libvirtd.enable = true;
  };

  # Socket-activate libvirtd to speed up critical boot chain
  systemd.services.libvirtd.wantedBy = lib.mkForce [];
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [];
}
