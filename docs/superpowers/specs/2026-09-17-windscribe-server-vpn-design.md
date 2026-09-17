# Always-on Windscribe WireGuard VPN for the server

Date: 2026-09-17
Status: Approved design (pending implementation)

## Goal

The `hosts/server` NixOS host must connect to Windscribe via WireGuard at boot
and stay connected. The VPN configuration is a Windscribe Static IP WireGuard
config provided by the user (`Windscribe-StaticIP-WG (1).conf`).

## Context

- VPN configuration lives in the local-only flake `/home/samuel/nixos-private`
  (per repo AGENTS.md), never in the public nixos-dotfiles repo.
- The existing shared private module `nixos-private/networking.nix` defines
  on-demand VPN interfaces (`madrid`, `wg0`, OpenVPN servers) and is imported
  by **both** the desktop host (`hosts/default`) and the server host
  (`hosts/server`). Always-on Windscribe must be **server-only** — the shared
  module stays untouched.
- VPN secrets follow the existing sops pattern: `hosts/server/configuration.nix`
  sets `sops.defaultSopsFile = ../../secrets/secrets.yaml` and the age key at
  `/home/samuel/.config/sops/age/keys.txt`.
- The server is reached via its public IP / port forwarding, so naive
  full-tunnel routing (`AllowedIPs = 0.0.0.0/0`) would blackhole inbound
  connections: replies would follow the new default route into the tunnel
  instead of back out the physical interface.

## Design

### 1. New private module: `nixos-private/server-vpn.nix`

Exported from the private flake as `nixosModules.server-vpn` and imported only
by `hosts/server/configuration.nix`.

### 2. WireGuard interface `windscribe`

Via `networking.wg-quick.interfaces.windscribe` with `autostart = true`:

- `address`: `100.84.165.120/32`, `fd54:4::8c74:8251:c1c3:382b/128`
  (static IPs from the provided config)
- Single peer:
  - `publicKey`: `G7LkwWk08Ase/Wi9mnOW77brNBC0vTCemvy1IW1nlV4=`
  - `endpoint`: `82.29.100.2:443`
  - `allowedIPs`: `0.0.0.0/0`, `::/0` (full tunnel)
  - `persistentKeepalive = 25` (keep NAT mapping alive)
- `privateKeyFile` / `presharedKeyFile` from sops secret paths (same pattern
  as `wireguard_madrid_*`).

### 3. Inbound-preservation policy rule

To keep inbound connections on the physical interface (SSH, port forwards)
working while all locally-originated traffic tunnels:

- `postUp`: resolve the current physical default-egress interface from the main
  table (`ip -o -4 route show to default | awk '{print $5; exit}'`) and add
  `ip rule add iif <iface> table main priority 100`.
- `preDown`: remove the same rule.

Rationale: wg-quick's `Table = auto` leaves the main table untouched and puts
the tunnel default in table 51820 selected by policy rules. The priority-100
rule catches only packets that *arrived on the physical interface* and routes
replies via the main (physical) table; local outbound traffic falls through to
the tunnel rule.

### 4. DNS

The wg interface config omits `DNS = 10.255.255.4`. The server keeps its
system DNS, which traverses the tunnel anyway; this avoids a resolvconf
dependency during early boot.

### 5. Secrets

Add to `secrets/secrets.yaml` via `sops set`:

- `wireguard_windscribe_private_key`
- `wireguard_windscribe_preshared_key`

The module declares both under `sops.secrets`. The private key value comes
from the `[Interface] PrivateKey` line of the provided config; the preshared
key from the `[Peer] PresharedKey` line.

## Error handling / failure modes

- WireGuard reconnects automatically on endpoint flaps.
- If the tunnel is down, the server falls back to the plain physical route:
  connectivity is preserved but **unencrypted**. This is "always connect," not
  a kill switch. Hard-blocking non-tunnel egress (a true kill switch) is
  explicitly out of scope.
- If `wg-quick-windscribe` fails at boot, systemd retries; the
  inbound-preservation rule is only installed on successful `postUp`, so no
  half-configured state.

## Verification

1. `nixos-rebuild build --flake .#server` in the dotfiles repo — config
   evaluates and builds.
2. After deploy on the server:
   - `systemctl status wg-quick-windscribe` — active.
   - `curl ifconfig.me` — returns the Windscribe static IP (`82.29.100.2`).
   - SSH to the server via its physical public IP still answers.
   - `ip rule show` — priority-100 iif rule present.

## Out of scope

- Desktop host (`hosts/default`) — unchanged.
- Shared `networking.nix` module — unchanged.
- Kill-switch firewall rules.
