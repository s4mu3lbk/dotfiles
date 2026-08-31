# Agent Instructions for NixOS Dotfiles

Welcome to `samuel`'s NixOS dotfiles repository! 

## Global Rules

1. **Shell Commands**: All shell commands must be written using **fish shell** syntax.

## General Information

- **Flake Location**: The main configuration entry point is `flake.nix` located at `/home/samuel/nixos-dotfiles/flake.nix`.
- **NixOS Configuration**: Managed through the `nixos` target (`.#nixos`).
- **Home Manager Configuration**: The Home Manager module is integrated directly into the NixOS flake in `flake.nix` under the `homeConfigurations` target for `samuel` (`.#samuel`).
- **Language**: The project heavily utilizes the Nix language. When making configurations, prefer native Nix or NixOS/Home Manager options.
- **Secrets**: API keys and sensitive data are managed via [sops-nix](https://github.com/Mic92/sops-nix). See `home/secrets.nix` and `secrets/secrets.yaml`. Never hardcode secrets in Nix files.
- **Private Modules**: VPN config, work infrastructure, and other non-public modules live in a separate local-only flake at `/home/samuel/nixos-private` (flake input `nixos-private`, `git+file://`). Keep sensitive config there — never in this repo.
- **Rebuilding System**: Typically, NixOS settings are applied via a rebuild command, e.g., using `sudo nixos-rebuild switch --flake .#nixos`.

## Project Structure

```
flake.nix                      # Entry point — defines nixosConfigurations + homeConfigurations
overlays.nix                   # Custom package overlays (binance, tradingview, etc.)
.sops.yaml                     # sops-nix encryption configuration

hosts/
├── default/
│   ├── configuration.nix      # Host entry point — imports system modules, wires home-manager
│   └── hardware.nix           # nixos-generate-config output
└── server/                    # Headless server (flake target .#server)
    ├── configuration.nix      # Server entry point — core modules only, no DE/desktop services
    └── hardware.nix           # Placeholder — replace with nixos-generate-config output

system/                        # NixOS system-level modules
├── default.nix                # Aggregator — imports all core modules
├── core/                      # nix.nix, boot.nix, networking.nix, services.nix,
│                              # virtualisation.nix, packages.nix, bluetooth.nix,
│                              # audio.nix, locale.nix, fonts.nix
├── de/                        # Desktop environments: kde.nix, gnome.nix, cosmic.nix
└── hardware/                  # Hardware-specific: asus.nix, power.nix

home/                          # Home Manager modules
├── home.nix                   # Entry point — imports all HM modules
├── server.nix                 # Minimal HM profile for the headless server (shell, git, tmux, nvim)
├── packages.nix               # User-level packages
├── secrets.nix                # sops-nix secret definitions + shell env loading
├── programs/                  # Per-app config (browser, git, ghostty, tmux, nvim, etc.)
├── shell/                     # Shell config (fish, nushell, bash, starship, lf, direnv)
└── theme/                     # Theming (colors.nix, dconf.nix, theme.nix)

packages/                      # Custom derivations exposed via overlays
├── antigravity/
├── binance/
├── carbonyl/
├── etcher/
├── nvim/                      # Custom neovim wrapper + lua config
└── tradingview/

scripts/                       # Utility scripts (nushell) + default.nix derivation builder
secrets/                       # Encrypted secrets (sops-nix / age)
```

Please follow these instructions explicitly when undertaking any new tasks or making tool calls in this environment.

## graphify

This project has a graphify knowledge graph at .graphify/.

Rules:
- Before answering architecture or codebase questions, read .graphify/GRAPH_REPORT.md for god nodes and community structure
- If .graphify/wiki/index.md exists, navigate it instead of reading raw files
- If .graphify/graph.json is missing but graphify-out/graph.json exists, run `graphify migrate-state --dry-run` first; if tracked legacy artifacts are reported, ask before using the recommended `git mv -f graphify-out .graphify` and commit message
- If .graphify/needs_update exists or .graphify/branch.json has stale=true, warn before relying on semantic results and run the graphify skill with --update when appropriate
- If the user asks to build, update, query, path, or explain the graph, use the installed `graphify` skill instead of ad-hoc file traversal
- Before proposing or committing .graphify artifacts, run `graphify portable-check .graphify`; commit-safe graph artifacts must use repo-relative paths, and never commit .graphify/branch.json, .graphify/worktree.json, .graphify/needs_update, or .graphify/cache/. If a repo already tracks any of them, first add them to .gitignore, then propose `git rm --cached .graphify/branch.json .graphify/worktree.json .graphify/needs_update` and `git rm -r --cached .graphify/cache`; never mutate git state without asking
- Before deep graph traversal, prefer `graphify summary --graph .graphify/graph.json` for compact first-hop orientation
- For review impact on changed files, use `graphify review-delta --graph .graphify/graph.json` instead of generic traversal
- After modifying code files in this session, run `npx graphify hook-rebuild` to keep the graph current
