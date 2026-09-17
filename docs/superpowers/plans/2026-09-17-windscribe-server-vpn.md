# Always-on Windscribe VPN for the server — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The `hosts/server` NixOS host connects to Windscribe via WireGuard at boot and stays connected, without breaking inbound SSH on the server's physical IP.

**Architecture:** A new `server-vpn` NixOS module in the local-only `/home/samuel/nixos-private` flake defines a `wg-quick` interface `windscribe` with `autostart = true` and a policy rule that keeps replies to physical-interface inbound traffic on the physical interface. Keys live in sops-encrypted `secrets/secrets.yaml`. Only `hosts/server` imports the module.

**Tech Stack:** Nix (NixOS modules), sops-nix, WireGuard/wg-quick.

**Spec:** `docs/superpowers/specs/2026-09-17-windscribe-server-vpn-design.md`

## Global Constraints

- VPN config and keys must NEVER be committed to the public nixos-dotfiles repo in plaintext. Only sops-encrypted values in `secrets/secrets.yaml` and the (public-by-nature) peer pubkey/endpoint/IPs go in files.
- WireGuard peer parameters (verbatim from the provided config): public key `G7LkwWk08Ase/Wi9mnOW77brNBC0vTCemvy1IW1nlV4=`, endpoint `82.29.100.2:443`, allowed IPs `0.0.0.0/0` + `::/0`, interface addresses `100.84.165.120/32` + `fd54:4::8c74:8251:c1c3:382b/128`.
- Source of secret values: `"$HOME/Downloads/Windscribe-StaticIP-WG (1).conf"` (`PrivateKey` / `PresharedKey` lines). Extract with awk — do NOT paste key values into commands as literals.
- `nixos-private` is a `git+file:///home/samuel/nixos-private` flake input; worktree changes are picked up without a `flake.lock` update.
- This is a Nix config change: "tests" are nix evaluation/build checks, not unit tests.
- After modifying code files, run `npx graphify hook-rebuild` (repo AGENTS.md rule).

---

### Task 1: Add Windscribe keys to sops secrets

**Files:**
- Modify: `secrets/secrets.yaml` (sops-encrypted, in the nixos-dotfiles repo)

**Interfaces:**
- Produces: sops secret names `wireguard_windscribe_private_key` and `wireguard_windscribe_preshared_key` — Task 2's module references these names via `config.sops.secrets.<name>.path`.

- [ ] **Step 1: Extract the keys from the WireGuard config and write them into secrets.yaml**

Run from `/home/samuel/nixos-dotfiles` (fish syntax; the awk output is never echoed):

```fish
set conf "$HOME/Downloads/Windscribe-StaticIP-WG (1).conf"
set priv (awk '/^PrivateKey =/{print $3}' $conf)
set psk (awk '/^PresharedKey =/{print $3}' $conf)
test -n "$priv"; and test -n "$psk"; or exit 1
sops set secrets/secrets.yaml '["wireguard_windscribe_private_key"]' "\"$priv\""
sops set secrets/secrets.yaml '["wireguard_windscribe_preshared_key"]' "\"$psk\""
```

Expected: `sops set` prints nothing on success, exits 0.

- [ ] **Step 2: Verify the keys exist (names only, values must not be printed)**

```fish
sops -d --output-type json secrets/secrets.yaml | jq -r 'keys[]' | grep windscribe
```

Expected output (order may vary):

```
wireguard_windscribe_preshared_key
wireguard_windscribe_private_key
```

- [ ] **Step 3: Commit**

```fish
git add secrets/secrets.yaml
git commit -m "secrets: add windscribe wireguard keys"
```

---

### Task 2: Create the server-vpn module in nixos-private

**Files:**
- Create: `/home/samuel/nixos-private/server-vpn.nix`
- Modify: `/home/samuel/nixos-private/flake.nix` (export the new module)

**Interfaces:**
- Consumes: sops secrets `wireguard_windscribe_private_key`, `wireguard_windscribe_preshared_key` (created in Task 1; the consuming host sets `sops.defaultSopsFile`/`sops.age.keyFile` already — see `hosts/server/configuration.nix:25-26`).
- Produces: flake output `inputs.nixos-private.nixosModules.server-vpn` — imported by Task 3.

- [ ] **Step 1: Write the module**

Create `/home/samuel/nixos-private/server-vpn.nix`:

```nix
# Always-on Windscribe WireGuard VPN — server host only.
# The host must provide sops secrets wireguard_windscribe_private_key and
# wireguard_windscribe_preshared_key (see nixos-dotfiles secrets/secrets.yaml).
{ config, ... }: {
  networking.wg-quick.interfaces.windscribe = {
    autostart = true;
    privateKeyFile = config.sops.secrets.wireguard_windscribe_private_key.path;
    address = [
      "100.84.165.120/32"
      "fd54:4::8c74:8251:c1c3:382b/128"
    ];

    peers = [
      {
        publicKey = "G7LkwWk08Ase/Wi9mnOW77brNBC0vTCemvy1IW1nlV4=";
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        endpoint = "82.29.100.2:443";
        presharedKeyFile = config.sops.secrets.wireguard_windscribe_preshared_key.path;
        persistentKeepalive = 25;
      }
    ];

    # Replies to connections that arrived on the physical interface must leave
    # via the physical interface; locally-originated traffic follows wg-quick's
    # tunnel table (51820).
    postUp = ''
      iface=$(ip -o -4 route show to default | awk '{print $5; exit}')
      ip rule add iif "$iface" table main priority 100
    '';
    preDown = ''
      iface=$(ip -o -4 route show to default | awk '{print $5; exit}')
      ip rule del iif "$iface" table main priority 100
    '';
  };

  sops.secrets = {
    wireguard_windscribe_private_key = { };
    wireguard_windscribe_preshared_key = { };
  };
}
```

- [ ] **Step 2: Export it from the private flake**

In `/home/samuel/nixos-private/flake.nix`, change the `nixosModules` attrset to:

```nix
    nixosModules = {
      networking = import ./networking.nix;
      server-vpn = import ./server-vpn.nix;
    };
```

- [ ] **Step 3: Commit in the nixos-private repo**

```fish
cd /home/samuel/nixos-private
git add server-vpn.nix flake.nix
git commit -m "add always-on windscribe wireguard module for server"
```

---

### Task 3: Import the module in the server host config

**Files:**
- Modify: `hosts/server/configuration.nix` (nixos-dotfiles repo)

**Interfaces:**
- Consumes: `inputs.nixos-private.nixosModules.server-vpn` (Task 2).
- Produces: complete `server` flake configuration including the windscribe interface.

- [ ] **Step 1: Add the import**

In `hosts/server/configuration.nix`, in the `imports` list, directly after line 21 (`inputs.nixos-private.nixosModules.networking`), add:

```nix
    # Always-on Windscribe VPN (server only) — from the local nixos-private flake
    inputs.nixos-private.nixosModules.server-vpn
```

- [ ] **Step 2: Commit**

```fish
git add hosts/server/configuration.nix
git commit -m "server: import always-on windscribe vpn module"
```

---

### Task 4: Build verification

**Files:**
- None (verification only)

- [ ] **Step 1: Build the server configuration**

```fish
cd /home/samuel/nixos-dotfiles
nixos-rebuild build --flake .#server
```

Expected: build succeeds, prints `nixos-rebuild` result path, exits 0. This evaluates the wg-quick unit, sops secret declarations, and the new module wiring without switching anything.

If evaluation fails with an error about `server-vpn` not found in the private flake input: the `git+file` input may be cached. Re-run with `--refresh`:

```fish
nixos-rebuild build --flake .#server --refresh
```

- [ ] **Step 2: Keep the graphify knowledge graph current**

```fish
npx graphify hook-rebuild
```

---

### Task 5: Deploy and verify on the server

> Requires root SSH access to the server. Run on (or targeted at) the server itself.

**Files:**
- None (deployment only)

- [ ] **Step 1: Switch the server to the new configuration**

```fish
sudo nixos-rebuild switch --flake /home/samuel/nixos-dotfiles#server
```

(Adjust the flake path if the dotfiles repo lives elsewhere on the server, or use `--flake github:<you>/nixos-dotfiles#server` / `--target-host` as appropriate.)

Expected: activation completes, `wg-quick-windscribe.service` starts.

- [ ] **Step 2: Verify the tunnel is up and is the default egress**

On the server:

```fish
systemctl status wg-quick-windscribe --no-pager
curl -s ifconfig.me
ip rule show
```

Expected:
- Service `active (exited)`.
- `curl` returns `82.29.100.2` (the Windscribe static IP).
- `ip rule show` includes a line like `100: from all iif <phys-iface> lookup main`.

- [ ] **Step 3: Verify inbound SSH on the physical IP still works**

From outside the server: open a NEW SSH session to the server's physical public IP (the one used before this change). It must connect. If it does not, on the server run `sudo systemctl stop wg-quick-windscribe` to restore plain routing, then investigate.

---

## Self-Review

- **Spec coverage:** module (spec §1–3) → Task 2; secrets (§5) → Task 1; host import (§1) → Task 3; build/deploy/verify (Verification) → Tasks 4–5; DNS omission (§4) → reflected in module code (no `dns` attr). Kill switch → explicitly out of scope, not planned. ✓
- **Placeholder scan:** no TBD/TODO/"handle edge cases"; all code blocks complete. Secret values are extracted by command, not literal — intentional (secrets must not appear in the repo's git history or docs). ✓
- **Type consistency:** sops secret names identical across Tasks 1 and 2 (`wireguard_windscribe_private_key`, `wireguard_windscribe_preshared_key`); flake output `nixosModules.server-vpn` matches between Tasks 2 and 3. ✓
