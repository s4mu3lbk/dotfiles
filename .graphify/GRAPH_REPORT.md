# Graph Report - .  (2026-09-17)

## Corpus Check
- Corpus is ~7,062 words - fits in a single context window. You may not need a graph.

## Summary
- 44 nodes · 22 edges · 5 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output
- Edge kinds: configures: 9 · includes: 8 · uses: 2 · based_on: 1 · documented_by: 1 · targets: 1


## Input Scope
- Requested: auto
- Resolved: committed (source: default-auto)
- Included files: 28 · Candidates: 107
- Excluded: 14 untracked · 3481 ignored · 2 sensitive · 0 missing committed
- Recommendation: Use --scope all or graphify.yaml inputs.corpus for a knowledge-base folder.

## Graph Freshness
- Built from Git commit: `ab146a6`
- Compare this hash to `git rev-parse HEAD` before trusting freshness-sensitive graph output.
## God Nodes (most connected - your core abstractions)
1. `Home Manager` - 9 edges
2. `NixOS Dotfiles` - 6 edges
3. `NixOS System Configuration` - 4 edges
4. `Flake Configuration` - 3 edges
5. `sops-nix Secrets` - 2 edges
6. `Neovim` - 2 edges
7. `Agent Instructions` - 2 edges
8. `KDE Plasma 6` - 1 edges
9. `Fish Shell` - 1 edges
10. `Nushell` - 1 edges

## Surprising Connections (you probably didn't know these)
- `NixOS Dotfiles` --includes--> `Systemd Boot Analysis`  [EXTRACTED]
  README.md → blame.html
- `NixOS Dotfiles` --documented_by--> `Agent Instructions`  [EXTRACTED]
  README.md → AGENTS.md
- `Neovim` --based_on--> `LazyVim`  [EXTRACTED]
  README.md → packages/nvim/README.md

## Hyperedges (group relationships)
- **Desktop Environments** — kde_plasma, hyprland [INFERRED 0.80]
- **Configured Browsers** — vivaldi, firefox_esr, qutebrowser [INFERRED 0.80]
- **Configured Shells** — fish_shell, nushell [INFERRED 0.80]

## Communities

### Community 0 - "Community 0"
Cohesion: 0.25
Nodes (8): Age Encryption, Agent Instructions, Custom Package Overlays, Graphify Rules, NixOS Dotfiles, Nushell Scripts, sops-nix Secrets, Systemd Boot Analysis

### Community 1 - "Community 1"
Cohesion: 0.25
Nodes (8): Firefox ESR, Fish Shell, Ghostty Terminal, Home Manager, Nushell, Qutebrowser, Tmux, Vivaldi Browser

### Community 2 - "Community 2"
Cohesion: 0.40
Nodes (5): ASUS Zenbook, Flake Configuration, KDE Plasma 6, NixOS System Configuration, System Modules

### Community 3 - "Community 3"
Cohesion: 1.00
Nodes (2): LazyVim, Neovim

### Community 8 - "Community 8"
Cohesion: 1.00
Nodes (1): Hyprland

## Knowledge Gaps
- **17 isolated node(s):** `KDE Plasma 6`, `Hyprland`, `Fish Shell`, `Nushell`, `Ghostty Terminal` (+12 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 3`** (2 nodes): `LazyVim`, `Neovim`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 8`** (1 nodes): `Hyprland`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Flake Configuration` connect `Community 2` to `Community 0`, `Community 1`?**
  _High betweenness centrality (0.168) - this node is a cross-community bridge._
- **Why does `Home Manager` connect `Community 1` to `Community 2`, `Community 3`?**
  _High betweenness centrality (0.168) - this node is a cross-community bridge._
- **Why does `NixOS Dotfiles` connect `Community 0` to `Community 2`?**
  _High betweenness centrality (0.137) - this node is a cross-community bridge._
- **What connects `KDE Plasma 6`, `Hyprland`, `Fish Shell` to the rest of the system?**
  _17 weakly-connected nodes found - possible documentation gaps or missing edges._