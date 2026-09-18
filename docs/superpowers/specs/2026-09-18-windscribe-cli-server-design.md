# Windscribe CLI + helper on the server — Design

**Date:** 2026-09-18
**Status:** Approved (design), pending spec review

## Goal

`windscribe-cli` is usable on the `hosts/server` NixOS host: the Windscribe helper daemon runs at boot and manages the VPN connection, and the user can log in / connect / check status over SSH. The existing wg-quick tunnel remains as a manual fallback.

## Current state

- The desktop host (`hosts/default`) gets the CLI via `system/core/windscribe.nix`, which provides:
  - `pkgs.windscribe` on `environment.systemPackages` (wrapper binaries `windscribe` and `windscribe-cli` in `packages/windscribe/default.nix`),
  - a read-only bind mount of `${pkgs.windscribe}/opt/windscribe` at `/opt/windscribe` (the helper rejects realpaths outside `/opt/windscribe`),
  - the `windscribe-helper` systemd service (`wantedBy = multi-user.target`).
- The server (`hosts/server`) imports only a subset of `system/core` and gets its VPN from `inputs.nixos-private.nixosModules.server-vpn` — an always-on wg-quick WireGuard tunnel (see `docs/superpowers/plans/2026-09-17-windscribe-server-vpn.md`).
- The server flake config already applies `overlays.nix` (`flake.nix:66-70`) and imports `system/core/nix.nix` which sets `nixpkgs.config.allowUnfree = true`, so `pkgs.windscribe` (unfree) is available to the server with no extra wiring.

## Constraints

- wg-quick and the helper must not both manage the default route. The helper is primary; wg-quick becomes a manual fallback (`autostart = false`).
- Inbound SSH on the server's physical IP must keep working while the tunnel is up (same problem the wg-quick setup solved with an `iif` policy rule).
- No secrets in the public repo. Windscribe account login is interactive (`windscribe-cli login`) and stores credentials in helper state on the server — nothing to commit.
- All shell commands use fish syntax.

## Changes

### 1. `hosts/server/configuration.nix` — import the windscribe module

Add to `imports`:

```nix
    # Windscribe CLI + helper daemon (same module the desktop uses)
    ../../system/core/windscribe.nix
```

No changes to `system/core/windscribe.nix` itself — it is desktop-agnostic (the GUI binary is inert on a headless host).

### 2. `/home/samuel/nixos-private/server-vpn.nix` — wg-quick as manual fallback

Set `autostart = false` on `networking.wg-quick.interfaces.windscribe`. Everything else in the module (keys, peers, policy rule in `postUp`/`preDown`) stays unchanged, so `sudo systemctl start wg-quick-windscribe` still works as before.

### 3. `hosts/server/configuration.nix` — keep inbound SSH replies on the physical interface

A oneshot systemd service installs the same policy rule the wg-quick `postUp` used, detected at runtime so it works regardless of interface name:

```nix
  # Keep replies to physical-interface inbound traffic (SSH) on the physical
  # interface while the Windscribe helper owns the default route.
  systemd.services.physical-iface-rule = {
    description = "Policy rule: answer inbound traffic on the physical interface";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ iproute2 gawk ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "physical-iface-rule-up" ''
        iface=$(ip -o -4 route show to default | awk '{print $5; exit}')
        ip rule add iif "$iface" table main priority 100 2>/dev/null || true
      '';
      ExecStop = pkgs.writeShellScript "physical-iface-rule-down" ''
        iface=$(ip -o -4 route show to default | awk '{print $5; exit}')
        ip rule del iif "$iface" table main priority 100 2>/dev/null || true
      '';
    };
  };
```

The rule is harmless when no VPN is connected (it just pins replies to the main table, which is the default behavior anyway). `|| true` keeps the unit from failing if the rule already exists (e.g. the wg-quick fallback is up).

## Operation after deploy

1. `ssh samuel@server`, then `windscribe-cli login` (once — credentials persist in helper state).
2. `windscribe-cli connect`. The helper reconnects on boot from persisted state.
3. Fallback if the helper misbehaves: `windscribe-cli disconnect`, then `sudo systemctl start wg-quick-windscribe`.

## Error handling / risks

- **Helper firewall blocks inbound SSH:** from an existing session, `windscribe-cli firewall off` (and/or `windscribe-cli lanbypass on` if the client supports it). Verified during deployment before closing the last session.
- **Rule/service failure:** the oneshot is non-fatal (`|| true`); worst case inbound SSH breaks only while the tunnel is connected, recoverable by `windscribe-cli disconnect` from an existing session or by starting the wg-quick fallback.
- **Package build:** the windscribe derivation is already built for the desktop, so the server build reuses the same store path.

## Verification

- `nixos-rebuild build --flake .#server` succeeds locally (evaluates the new import, service, and the updated private module).
- On the server after switch:
  - `systemctl status windscribe-helper --no-pager` → active.
  - `windscribe-cli login` + `windscribe-cli connect`, then `windscribe-cli status` → CONNECTED.
  - `curl -s ifconfig.me` → a Windscribe IP (not the physical IP).
  - A **new** SSH session to the server's physical IP connects while the tunnel is up.
  - `sudo systemctl stop windscribe-helper`-style failure drill (optional): `sudo systemctl start wg-quick-windscribe` restores connectivity.

## Out of scope

- Kill-switch semantics beyond the helper's own firewall setting.
- Automating `windscribe-cli login` (interactive by design).
- The COSMIC specialisation on the server (untouched; the module is already inert there beyond what the desktop does).
