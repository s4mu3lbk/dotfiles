{ pkgs, ... }: {
  users.groups.windscribe = {};

  environment.systemPackages = [ pkgs.windscribe ];

  # Use a bind mount instead of a symlink so that realpath("/opt/windscribe")
  # returns "/opt/windscribe" (not the Nix store path). The helper binary
  # validates executables via realpath and rejects paths outside /opt/windscribe.
  systemd.tmpfiles.rules = [
    "d /opt/windscribe 0755 root root -"
  ];
  fileSystems."/opt/windscribe" = {
    device = "${pkgs.windscribe}/opt/windscribe";
    fsType = "none";
    options = [ "bind" "ro" ];
  };

  systemd.services.windscribe-helper = {
    description = "Windscribe helper service";
    after = [ "firewall.service" "systemd-tmpfiles-setup.service" ];
    before = [ "network-pre.target" ];
    wants = [ "network-pre.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ iptables iproute2 wireguard-tools amneziawg-tools amneziawg-go kmod openresolv systemd procps dbus nettools openvpn ] ++ [ "/opt/windscribe" "/run/wrappers" ];
    environment = {
      WG_I_PREFER_BUGGY_USERSPACE_TO_POLISHED_KMOD = "1";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "/opt/windscribe/helper";
      Restart = "on-failure";
    };
  };
}
