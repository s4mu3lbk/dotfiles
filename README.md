# Samuel's NixOS Dotfiles

Personal NixOS configuration using flakes, Home Manager, and modular system management.

## Overview

| Component | Description |
|-----------|-------------|
| **OS** | NixOS (unstable) |
| **DE** | KDE Plasma 6 (default), COSMIC (specialisation) |
| **Shell** | Fish (primary), Nushell, Bash |
| **Terminal** | Ghostty + Tmux |
| **Editor** | Neovim (custom wrapper) |
| **Browser** | Vivaldi (primary), Firefox ESR, Qutebrowser |
| **Secrets** | [sops-nix](https://github.com/Mic92/sops-nix) (age encryption) |
| **Hardware** | ASUS Zenbook (Intel iGPU) |

## Project Structure

```
flake.nix                      # Entry point — nixosConfigurations + homeConfigurations
overlays.nix                   # Custom package overlays
.sops.yaml                     # sops-nix encryption config

hosts/
└── default/
    ├── configuration.nix      # Host entry point — imports system modules, wires home-manager
    └── hardware.nix           # nixos-generate-config output

system/                        # NixOS system-level modules
├── default.nix                # Aggregator — imports all core modules
├── core/                      # nix, boot, networking, services, virtualisation,
│                              # packages, bluetooth, audio, locale, fonts
├── de/                        # Desktop environments: kde, gnome, cosmic
└── hardware/                  # Hardware-specific: asus, power

home/                          # Home Manager modules
├── home.nix                   # Entry point — imports all HM modules
├── packages.nix               # User-level packages
├── secrets.nix                # sops-nix secret definitions + shell env loading
├── programs/                  # Per-app config (browser, git, ghostty, tmux, nvim, etc.)
├── shell/                     # Shell config (fish, nushell, bash, starship, lf, direnv)
└── theme/                     # Theming (colors, dconf, theme)

packages/                      # Custom derivations exposed via overlays
├── antigravity/
├── binance/
├── carbonyl/
├── nvim/                      # Custom neovim wrapper + lua config
└── tradingview/

scripts/                       # Utility scripts (nushell) + derivation builder
secrets/                       # Encrypted secrets (sops-nix)
```

## Usage

### Full system rebuild

```fish
sudo nixos-rebuild switch --flake .#nixos
```

### Home Manager only

```fish
home-manager switch --flake .#samuel -b backup
```

## Secrets Setup

This repo uses [sops-nix](https://github.com/Mic92/sops-nix) for encrypted secret management.

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
