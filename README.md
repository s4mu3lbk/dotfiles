# Samuel's NixOS Dotfiles

Personal NixOS configuration using flakes, Home Manager, and modular system management.

## Overview

| Component | Description |
|-----------|-------------|
| **OS** | NixOS (unstable) |
| **Hosts** | `nixos` (desktop), `server` (headless server) |
| **DE** | KDE Plasma 6 (default), COSMIC (specialisation) — desktop only |
| **Shell** | Fish (primary), Nushell, Bash |
| **Terminal** | Ghostty + Tmux |
| **Editor** | Neovim (custom wrapper) |
| **Browser** | Vivaldi (primary), Firefox ESR, Qutebrowser |
| **Secrets** | [sops-nix](https://github.com/Mic92/sops-nix) (age encryption) |
| **Hardware** | ASUS Zenbook (Intel iGPU) — desktop |

## Project Structure

```
flake.nix                      # Entry point — nixosConfigurations + homeConfigurations
overlays.nix                   # Custom package overlays
.sops.yaml                     # sops-nix encryption config

hosts/
├── default/
│   ├── configuration.nix      # Desktop host — imports system modules, wires home-manager
│   └── hardware.nix           # nixos-generate-config output
└── server/                    # Headless server (flake target .#server)
    ├── configuration.nix      # Core modules only — no DE, audio, bluetooth, or desktop services
    └── hardware.nix           # nixos-generate-config output (per server machine)

system/                        # NixOS system-level modules
├── default.nix                # Aggregator — imports all core modules
├── core/                      # nix, boot, networking, services, virtualisation,
│                              # packages, bluetooth, audio, locale, fonts
├── de/                        # Desktop environments: kde, gnome, cosmic
└── hardware/                  # Hardware-specific: asus, power

home/                          # Home Manager modules
├── home.nix                   # Desktop entry point — imports all HM modules
├── server.nix                 # Minimal headless HM profile (shell, git, tmux, nvim, secrets)
├── packages.nix               # User-level packages (desktop)
├── secrets.nix                # sops-nix secret definitions + shell env loading
├── programs/                  # Per-app config (browser, git, ghostty, tmux, nvim, etc.)
├── shell/                     # Shell config (fish, nushell, bash, starship, lf, direnv)
└── theme/                     # Theming (colors, dconf, theme)

packages/                      # Custom derivations exposed via overlays
├── antigravity/
├── antigravity-ide/           # Binary fetched via requireFile (not tracked in git)
├── binance/
├── carbonyl/
├── nvim/                      # Custom neovim wrapper + lua config
└── tradingview/

scripts/                       # Utility scripts (nushell) + derivation builder
secrets/                       # Encrypted secrets (sops-nix)
```

## Private flake inputs

This flake references two **local-path inputs** that are not published:

- `nixos-private` (`git+file:///home/samuel/nixos-private`) — VPN configs, work
  infrastructure, and other private NixOS/HM modules. Kept in a separate repo so
  this one can stay public.
- `viscus` (`git+file:///home/samuel/Projects/self/viscus`) — personal project package.

Both paths must exist on any machine that evaluates this flake (inputs are fetched
at evaluation time even when unused). To build this config yourself, replace these
inputs with your own or remove the corresponding imports.

## Usage

### Desktop: full system rebuild

```fish
sudo nixos-rebuild switch --flake .#nixos
```

### Home Manager only

```fish
home-manager switch --flake .#samuel -b backup
```

### Server

The `server` host is a headless configuration: core modules only (nix, boot,
networking, locale, virtualisation), hardened SSH (key-only auth, no root login),
and a minimal Home Manager profile for the admin user.

```fish
# verify the build locally first
nixos-rebuild build --flake .#server

# fresh install from a NixOS installer (repo copied to the machine)
sudo nixos-install --flake /home/samuel/nixos-dotfiles#server

# or remote deploy to a running server (builds locally, activates remotely)
nixos-rebuild switch --flake .#server --target-host samuel@server --sudo
```

Before the first server build:

1. Run `nixos-generate-config` on the server and copy the result into
   `hosts/server/hardware.nix` (note: `system/core/boot.nix` assumes
   systemd-boot/EFI — override with GRUB for legacy/BIOS machines).
2. Copy the private flake inputs (`nixos-private`, `viscus`) to the same
   absolute paths on the server.
3. Copy the sops age key to `~/.config/sops/age/keys.txt` (mode 600) **before**
   the first activation, or secret decryption will fail.
4. Add real SSH public keys for all users — SSH is key-only.

## Secrets Setup

This repo uses [sops-nix](https://github.com/Mic92/sops-nix) for encrypted secret management.
`secrets/secrets.yaml` is committed encrypted and is safe to publish; the age **private**
key never enters the repo.

```fish
# 1. Generate an age key pair
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# 2. Get your public key and update .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt

# 3. Create and encrypt secrets
sops secrets/secrets.yaml
```

## License

[GPL-3.0](LICENSE)
