# Networking: NetworkManager, firewall
# NOTE: VPN interfaces (WireGuard/OpenVPN), sops-managed VPN keys, and custom
# /etc/hosts entries were removed from the public repo. Keep them in a private
# flake input/module and import it from your host configuration if needed.
{...}: {
  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  # KDE Connect ports
  networking.firewall = rec {
    allowedTCPPorts = [ 4096 ];
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };
}
