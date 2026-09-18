# Design: Automated Package Updates for NixOS Dotfiles

**Date:** 2026-07-08
**Scope:** Extend `scripts/update-package.nu` to update all custom packages in `packages/` automatically.

## Background

The repository contains several custom packages under `packages/` that are wired into the NixOS/Home Manager configuration via `overlays.nix`. Today these are updated by hand: check the upstream release, bump `version`, prefetch the new artifact, and update the hash in `default.nix`.

A nushell script already exists at `scripts/update-package.nu`, but it only handles `fetchurl`-based GitHub packages and does not support `fetchzip`, `fetchgit`, or a bulk `--all` mode.

## Goals

- Run `update-package --all` to check every package in `packages/` for updates.
- Support `fetchurl`, `fetchzip`, and `fetchgit` fetchers.
- Handle common GitHub release tag formats including scoped npm-style tags such as `@moonshot-ai/kimi-code@0.23.2`.
- Modify `default.nix` files only; do not stage or commit changes.
- Validate each update by instantiating the derivation before keeping the change.
- Provide `--dry-run`, `--flake`, and per-package `--file` workflows.

## Non-goals

- Automatic commits or PRs.
- Updating packages that are not hosted on GitHub or do not expose releases.
- Building every updated package by default (instantiation only; optional `--build` may be added later).

## CLI

```nu
update-package <package>            # update one package
update-package --all                # update all packages in packages/
update-package --all --flake        # also run `nix flake update`
update-package --all --dry-run      # preview only
update-package <package> --file ... # existing local-binary workflow
```

## Design

### Fetcher detection

The script reads `packages/<name>/default.nix` and classifies the package:

- Remote GitHub package: file contains `fetchurl`, `fetchzip`, or `fetchgit` and a GitHub URL/homepage.
- Local binary package: file contains `src = ./<filename>`.

### GitHub release flow

1. Parse `owner/repo` from `meta.homepage` or the `url` string.
2. Query `https://api.github.com/repos/{owner}/{repo}/releases/latest`.
3. Extract the version from `tag_name`:
   - `v1.2.3` -> `1.2.3`
   - `1.2.3` -> `1.2.3`
   - `@scope/name@1.2.3` -> `1.2.3`
4. Compare with the current `version` in `default.nix`. Skip if equal.
5. Pick the release asset:
   - Match the current filename's extension (`.deb`, `.zip`, `.tar.gz`, etc.).
   - Prefer assets containing `x86_64`, `amd64`, `linux`, or `linux-x64`.
6. Prefetch the asset:
   - `fetchurl` / `fetchzip` -> `nix-prefetch-url <asset-url>`
   - `fetchgit` -> `nix-prefetch-git --url <repo-url> --rev <tag>`
7. Update `version` and `hash`/`sha256` in `default.nix`.
8. Run `nix-instantiate` on the package. If it fails, revert the file and record the failure.

### Local binary flow

Keep the existing behavior: require `--file /path/to/binary`, prompt for a new version, copy the file into `packages/<name>/`, and update `version` in `default.nix`.

### `--all` loop

Iterate every subdirectory of `packages/`. For each:

- Classify the package.
- Attempt the appropriate update flow.
- Collect successes and failures.
- Print a summary at the end.

Failures in one package must not stop the loop.

### `--flake`

When passed, run `nix flake update` after package updates finish successfully. This is disabled during `--dry-run`.

### `--dry-run`

Prints the detected current version, latest version, and asset URL for each package without modifying any files.

## Error handling

- GitHub API failures are caught and reported per-package.
- Missing assets are reported with the list of available assets.
- Prefetch failures revert any partial change.
- `nix-instantiate` failures revert the `default.nix` change for that package.
- All failures are summarized at the end of `--all`.

## Testing

1. `update-package kimi-cli --dry-run` should detect `0.23.2` without writing files.
2. `update-package kimi-cli` should update `packages/kimi-cli/default.nix` and instantiate successfully.
3. `update-package --all --dry-run` should classify every package and report what it would do.
4. Fix edge cases for packages with non-standard asset naming as they appear.

## Files changed

- `scripts/update-package.nu` — extended logic and new flags.
- `scripts/default.nix` — no change; the existing script entry remains.

## Future work

- Optional `--build` flag to build each updated package.
- GitHub Actions workflow that runs `--all --dry-run` on a schedule and opens an issue when updates are available.
