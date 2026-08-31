# cosmic-monitor Installation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `cosmic.monitor.enable` option (default `true`) that installs `pkgs.cosmic-monitor` when the COSMIC desktop environment is enabled.

**Architecture:** Extend the existing COSMIC desktop module at `system/de/cosmic.nix` with a new option and a conditional `environment.systemPackages` entry. Validate the change with `nix flake check` and a `nixos-rebuild build`.

**Tech Stack:** Nix language, NixOS, nixpkgs unstable.

## Global Constraints

- Keep all changes inside `system/de/cosmic.nix`.
- Follow the existing module style (e.g., `lib.mkEnableOption`, `lib.mkIf`, `with pkgs;`).
- Do not hardcode secrets or paths.
- `cosmic.enable` remains the top-level gate; the monitor option only matters when COSMIC is enabled.

---

### Task 1: Add the `cosmic.monitor.enable` option

**Files:**
- Modify: `system/de/cosmic.nix:7-9`

**Interfaces:**
- Produces: `options.cosmic.monitor.enable` (boolean, default `true`).

- [ ] **Step 1: Add the option definition**

Change the `options.cosmic` block from:

```nix
  options.cosmic = {
    enable = lib.mkEnableOption "Cosmic Desktop";
  };
```

to:

```nix
  options.cosmic = {
    enable = lib.mkEnableOption "Cosmic Desktop";
    monitor.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the COSMIC System Monitor.";
    };
  };
```

- [ ] **Step 2: Verify no syntax errors**

Run: `nix flake check`

Expected: command exits `0`.

---

### Task 2: Install `cosmic-monitor` conditionally

**Files:**
- Modify: `system/de/cosmic.nix:38-41`

**Interfaces:**
- Consumes: `config.cosmic.monitor.enable`.
- Produces: `environment.systemPackages` containing `pkgs.cosmic-monitor` when enabled.

- [ ] **Step 1: Replace the empty system package list**

Change:

```nix
    environment.systemPackages =
      # with inputs.nixos-cosmic.packages.x86_64-linux; [
      with pkgs; [
      ];
```

to:

```nix
    environment.systemPackages = lib.mkIf config.cosmic.monitor.enable (with pkgs; [
      cosmic-monitor
    ]);
```

- [ ] **Step 2: Validate the flake**

Run: `nix flake check`

Expected: command exits `0`.

- [ ] **Step 3: Build the NixOS configuration**

Run: `nixos-rebuild build --flake .#nixos`

Expected: build succeeds and creates `./result`.

- [ ] **Step 4: Confirm the package is in the closure**

Run: `nix path-info -r ./result | grep cosmic-monitor`

Expected: at least one line containing `cosmic-monitor`.

- [ ] **Step 5: Commit the change**

```bash
git add system/de/cosmic.nix
git commit -m "feat: add cosmic-monitor to COSMIC desktop module"
```

---

## Spec Coverage

- Spec section "Add a new toggle option `cosmic.monitor.enable`" → Task 1.
- Spec section "Package installation" → Task 2.
- Spec section "Validation" → Steps in Task 1 and Task 2.

## Placeholder Scan

No placeholders or vague steps remain; each step contains exact file paths, code, and expected command output.
