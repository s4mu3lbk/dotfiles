# Windscribe CLI + Helper on the Server — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `windscribe-cli` works on the `hosts/server` NixOS host, with the Windscribe helper daemon managing the VPN at boot and the existing wg-quick tunnel kept as a manual fallback.

**Architecture:** The server imports the existing `system/core/windscribe.nix` module (package + `/opt/windscribe` bind mount + `windscribe-helper` systemd service — unchanged, shared with the desktop). The wg-quick interface in the private flake loses `autostart`. A small oneshot service on the server pins inbound replies to the physical interface so SSH survives the tunnel.

**Tech Stack:** Nix (NixOS modules), systemd, wg-quick.

**Spec:** `docs/superpowers/specs/2026-09-18-windscribe-cli-server-design.md`

## Global Constraints

- All shell commands use **fish** syntax (repo AGENTS.md rule).
- No secrets in the public repo. Windscribe login is interactive on the server (`windscribe-cli login`) — nothing credential-shaped goes into any file or commit.
- The private flake is `inputs.nixos-private` (`git+ssh://git@github.com/s4mu3lbk/dotfiles-private.git`, local checkout at `/home/samuel/nixos-private`). Nix picks up its committed state; after editing it, commit there before rebuilding the server config.
- "Tests" for this Nix config are evaluation/build checks (`nixos-rebuild build`), not unit tests.
- After modifying code files, run `npx graphify hook-rebuild` (repo AGENTS.md rule).
- Do not modify `system/core/windscribe.nix` or `packages/windscribe/default.nix` — they are shared with the desktop and already correct.

---

### Task 1: Disable wg-quick autostart in the private flake

**Files:**
- Modify: `/home/samuel/nixos-private/server-vpn.nix`

**Interfaces:**
- Produces: `networking.wg-quick.interfaces.windscribe.autostart = false` — the interface stays defined with keys, peers, addresses, and its own `postUp`/`preDown` policy rule, so `sudo systemctl start wg-quick-windscribe` still works manually. Task 2's build consumes this through `inputs.nixos-private.nixosModules.server-vpn`.

- [ ] **Step 1: Read the current module**

```fish
cat /home/samuel/nixos-private/server-vpn.nix
```

Expected: a module defining `networking.wg-quick.interfaces.windscribe` with `autostart = true;` near the top, plus `sops.secrets` for `wireguard_windscribe_private_key` and `wireguard_windscribe_preshared_key`. If the file is missing, stop — the server config already imports this module, so something is out of sync; report back instead of improvising.

- [ ] **Step 2: Change autostart to false**

Edit `/home/samuel/nixos-private/server-vpn.nix`: replace the line

```nix
    autostart = true;
```

with

```nix
    # Manual fallback only — the windscribe-helper service (see
    # system/core/windscribe.nix in nixos-dotfiles) is primary on this host.
    autostart = false;
```

- [ ] **Step 3: Commit in the private repo**

```fish
cd /home/samuel/nixos-private
git add server-vpn.nix
git commit -m "server-vpn: disable wg-quick autostart (helper is primary now)"
```

---

### Task 2: Import the windscribe module and add the SSH-survival rule

**Files:**
- Modify: `hosts/server/configuration.nix` (imports list at lines 10-28; add a new block after the sops lines 30-32)

**Interfaces:**
- Consumes: `../../system/core/windscribe.nix` (existing module: `pkgs.windscribe` on PATH, `/opt/windscribe` bind mount, `windscribe-helper` service); the updated `inputs.nixos-private.nixosModules.server-vpn` from Task 1.
- Produces: a server configuration where `windscribe-cli` is on PATH, `windscribe-helper.service` starts at boot, and `physical-iface-rule.service` pins inbound replies to the physical interface. `hosts/server/configuration.nix` already receives `pkgs` in its arguments (line 6), so `pkgs.iproute2`, `pkgs.gawk`, and `pkgs.writeShellScript` are in scope.

- [ ] **Step 1: Add the module import**

In `hosts/server/configuration.nix`, in the `imports` list, directly after the lines

```nix
    # Always-on Windscribe VPN (server only) — from the local nixos-private flake
    inputs.nixos-private.nixosModules.server-vpn
```

add:

```nix

    # Windscribe CLI + helper daemon (same module the desktop uses)
    ../../system/core/windscribe.nix
```

- [ ] **Step 2: Add the physical-interface policy rule service**

In `hosts/server/configuration.nix`, directly after the lines

```nix
  # sops targets for the private networking module's VPN secrets
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/samuel/.config/sops/age/keys.txt";
```

add:

```nix

  # Keep replies to physical-interface inbound traffic (SSH) on the physical
  # interface while the Windscribe helper owns the default route. Harmless
  # when no VPN is up; || true tolerates the rule already existing (e.g. the
  # wg-quick fallback added the same rule in its postUp).
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

- [ ] **Step 3: Build the server configuration**

From `/home/samuel/nixos-dotfiles`:

```fish
nixos-rebuild build --flake .#server
```

Expected: build succeeds and prints a `result` store path, exit 0. This evaluates the module import, the new service, and the updated private module without switching anything.

If evaluation complains that `server-vpn` still has stale content or the input seems cached, re-run with:

```fish
nixos-rebuild build --flake .#server --refresh
```

- [ ] **Step 4: Keep the graphify knowledge graph current**

```fish
npx graphify hook-rebuild
```

- [ ] **Step 5: Commit**

```fish
cd /home/samuel/nixos-dotfiles
git add hosts/server/configuration.nix
git commit -m "server: add windscribe cli + helper, keep inbound ssh on physical iface"
```

---

### Task 3: Deploy and verify on the server

> Requires SSH access to the server with sudo. Run from an existing SSH session (or locally with `--target-host`). Do not close the last working session until Step 4 passes.

**Files:**
- None (deployment + verification only)

- [ ] **Step 1: Switch the server to the new configuration**

On the server (adjust the flake path if the checkout lives elsewhere):

```fish
sudo nixos-rebuild switch --flake /home/samuel/nixos-dotfiles#server
```

Expected: activation completes; `windscribe-helper.service` and `physical-iface-rule.service` start; `wg-quick-windscribe.service` does **not** start.

Confirm:

```fish
systemctl is-active windscribe-helper physical-iface-rule
systemctl is-active wg-quick-windscribe
```

Expected: `active`, `active`, then `inactive` (or `failed` only if it was mid-transition — `inactive` is the goal state).

- [ ] **Step 2: Log in and connect via the CLI**

```fish
windscribe-cli login
windscribe-cli connect
windscribe-cli status
```

Expected: after entering credentials, status shows `CONNECTED`. (Login state persists in helper state across reboots; this is a one-time interactive step.)

- [ ] **Step 3: Verify egress goes through Windscribe**

```fish
curl -s ifconfig.me
ip rule show
```

Expected: the IP is a Windscribe IP (not the server's physical IP), and `ip rule show` contains a line like `100: from all iif <phys-iface> lookup main`.

- [ ] **Step 4: Verify inbound SSH on the physical IP still works**

From another machine, open a **new** SSH session to the server's physical IP. It must connect. If it does not, from the still-open original session run:

```fish
windscribe-cli firewall off
```

and retry; if still broken, `windscribe-cli disconnect`, confirm SSH recovers, then fall back with `sudo systemctl start wg-quick-windscribe` and investigate before re-attempting.

- [ ] **Step 5: Verify the fallback path (optional but recommended)**

```fish
windscribe-cli disconnect
sudo systemctl start wg-quick-windscribe
curl -s ifconfig.me
```

Expected: the Windscribe static IP from the wg-quick config (`82.29.100.2`). Then restore the primary setup:

```fish
sudo systemctl stop wg-quick-windscribe
windscribe-cli connect
```

---

## Self-Review

- **Spec coverage:** import windscribe module (spec Change 1) → Task 2 Step 1; wg-quick autostart off (Change 2) → Task 1; policy rule service (Change 3) → Task 2 Step 2; operation/login (spec "Operation") → Task 3 Steps 2-3; firewall/SSH risk (spec "Error handling") → Task 3 Step 4; fallback (spec "Error handling") → Task 3 Steps 1+5; build verification (spec "Verification") → Task 2 Step 3. ✓
- **Placeholder scan:** no TBD/TODO; all code blocks complete; every command has an expected result. ✓
- **Type/name consistency:** module path `../../system/core/windscribe.nix` matches the repo layout from `hosts/server/`; service names `physical-iface-rule`, `windscribe-helper`, `wg-quick-windscribe` are used identically in Tasks 2 and 3; sops secret names referenced in Task 1 match the existing module untouched by this plan. ✓
