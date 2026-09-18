# Automated Package Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `scripts/update-package.nu` so it can automatically update all custom packages in `packages/`, supporting `fetchurl`, `fetchzip`, `fetchgit`, scoped GitHub tags, `--all`, `--flake`, and `--dry-run`.

**Architecture:** Keep the existing nushell script but refactor it into three high-level flows: single-package remote update, single-package local-binary update, and bulk `--all` orchestration. Introduce small helper commands for version extraction, asset matching, and derivation validation. All changes live in `scripts/update-package.nu`.

**Tech Stack:** Nushell, GitHub REST API, `nix-prefetch-url`, `nix-prefetch-git`, `nix-instantiate`.

## Global Constraints

- Modify `default.nix` files only; do not stage or commit changes.
- Support `fetchurl`, `fetchzip`, and `fetchgit`.
- Handle scoped npm-style tags such as `@moonshot-ai/kimi-code@0.23.2`.
- Validate each update by instantiating the derivation before keeping the change.
- Failures in one package during `--all` must not stop the loop.

---

## Task 1: Refactor CLI entry point and flags

**Files:**
- Modify: `scripts/update-package.nu:10-39`

**Interfaces:**
- Consumes: none.
- Produces: a `main` command that accepts `package?: string`, `--all`, `--flake`, `--dry-run`, and `--file: path`.

- [ ] **Step 1: Update the `main` signature**

Replace the current single-parameter `main` with:

```nu
def main [
    package?: string,
    --all,
    --flake,
    --dry-run,
    --file (-f): path
] {
    let repo_root = ($env.FILE_PWD? | default "/home/samuel/nixos-dotfiles" | path join "..")

    if $flake and not $all {
        print -e "Error: --flake can only be used with --all"
        exit 1
    }

    if $dry_run {
        print "[dry-run] No files will be modified."
    }

    if $all {
        update-all $repo_root $flake $dry_run
    } else if ($package | is-empty) {
        print -e "Error: Provide a package name or use --all"
        exit 1
    } else {
        update-one $package $repo_root $dry_run $file
    }
}
```

- [ ] **Step 2: Verify the script parses**

Run:

```bash
nu -c 'source scripts/update-package.nu'
```

Expected: no parse errors.

- [ ] **Step 3: Commit**

```bash
git add scripts/update-package.nu
git commit -m "feat(update-package): add --all, --flake, --dry-run flags"
```

---

## Task 2: Extract helpers for fetcher classification and version parsing

**Files:**
- Modify: `scripts/update-package.nu` (append helpers before the existing update functions)

**Interfaces:**
- Consumes: `default.nix` content string.
- Produces: `get-fetcher-type`, `extract-version`, `parse-github-repo`, `extract-github-version`.

- [ ] **Step 1: Add `get-fetcher-type`**

```nu
def get-fetcher-type [content: string] {
    if ($content | str contains "fetchurl") {
        "fetchurl"
    } else if ($content | str contains "fetchzip") {
        "fetchzip"
    } else if ($content | str contains "fetchgit") {
        "fetchgit"
    } else if ($content | str contains "src = ./") {
        "local"
    } else {
        "unknown"
    }
}
```

- [ ] **Step 2: Add `extract-version`**

```nu
def extract-version [content: string] {
    let match = ($content | parse -r 'version\s*=\s*"([^"]+)"')
    if ($match | is-empty) {
        null
    } else {
        $match.capture0.0
    }
}
```

- [ ] **Step 3: Add `parse-github-repo`**

```nu
def parse-github-repo [content: string] {
    let homepage_match = ($content | parse -r 'homepage\s*=\s*"([^"]+)"')
    let url_match = ($content | parse -r 'url\s*=\s*"([^"]+)"')

    let candidate = if ($homepage_match | is-not-empty) and ($homepage_match.capture0.0 | str contains "github.com") {
        $homepage_match.capture0.0
    } else if ($url_match | is-not-empty) and ($url_match.capture0.0 | str contains "github.com") {
        $url_match.capture0.0
    } else {
        null
    }

    if ($candidate | is-empty) {
        null
    } else {
        let parsed = ($candidate | parse -r 'https://github.com/([^/]+/[^/]+)')
        if ($parsed | is-empty) {
            null
        } else {
            $parsed.capture0.0 | str replace -r '/$' ''
        }
    }
}
```

- [ ] **Step 4: Add `extract-github-version`**

```nu
def extract-github-version [tag_name: string] {
    # Handle v1.2.3, 1.2.3, @scope/name@1.2.3
    let parsed = ($tag_name | parse -r '@?[^@]*@([0-9]+\.[0-9]+\.[0-9]+.*)')
    if ($parsed | is-not-empty) {
        $parsed.capture0.0
    } else {
        let simple = ($tag_name | parse -r '^v?([0-9]+\.[0-9]+\.[0-9]+.*)')
        if ($simple | is-empty) {
            null
        } else {
            $simple.capture0.0
        }
    }
}
```

- [ ] **Step 5: Add `normalize-hash` helper**

```nu
def normalize-hash [hash: string, attr_name: string] {
    let is_sri = ($hash | str starts-with "sha256-")
    if ($attr_name | str contains "hash") {
        if $is_sri { $hash } else { (nix hash convert --hash-algo sha256 --to sri $hash | str trim) }
    } else {
        if $is_sri { (nix hash convert --hash-algo sha256 --to nix32 $hash | str trim) } else { $hash }
    }
}
```

- [ ] **Step 6: Verify helpers parse**

Run:

```bash
nu -c 'source scripts/update-package.nu; extract-github-version "@moonshot-ai/kimi-code@0.23.2"'
```

Expected output: `0.23.2`

- [ ] **Step 7: Update `update-nix-file` to normalize hashes**

Replace the hash-updating branch with:

```nu
def update-nix-file [file: path, old_version: string, new_version: string, hash?: string] {
    let content = (open $file)
    let updated = ($content | str replace $"version = \"($old_version)\"" $"version = \"($new_version)\"")

    let final = if ($hash | is-not-empty) {
        if ($updated | str contains "sha256 =") {
            let normalized = (normalize-hash $hash "sha256")
            $updated | str replace -r 'sha256 = "[^"]+"' $"sha256 = \"($normalized)\""
        } else if ($updated | str contains "hash =") {
            let normalized = (normalize-hash $hash "hash")
            $updated | str replace -r 'hash = "[^"]+"' $"hash = \"($normalized)\""
        } else {
            print -e "Warning: Could not find hash/sha256 attribute to update"
            $updated
        }
    } else {
        $updated
    }

    $final | save -f $file
}
```

- [ ] **Step 8: Commit**

```bash
git add scripts/update-package.nu
git commit -m "feat(update-package): add fetcher/version helpers"
```

---

## Task 3: Generalize remote package update for fetchurl/fetchzip/fetchgit

**Files:**
- Modify: `scripts/update-package.nu:41-141`

**Interfaces:**
- Consumes: `package`, `pkg_dir`, `default_nix`, `content`, `dry_run`.
- Produces: updated `default.nix` (unless dry-run).

- [ ] **Step 1: Rename and refactor `update-fetchurl-package` to `update-remote-package`**

Replace the existing function with:

```nu
def update-remote-package [package: string, repo_root: path, pkg_dir: path, default_nix: path, content: string, dry_run: bool] {
    let fetcher = (get-fetcher-type $content)
    let repo = (parse-github-repo $content)

    if ($repo | is-empty) {
        print -e $"Error: Could not parse GitHub repository for ($package)"
        exit 1
    }

    print $"Checking GitHub releases for ($repo)..."

    let latest = try {
        http get $"https://api.github.com/repos/($repo)/releases/latest"
    } catch { |e|
        print -e $"Error: Failed to fetch releases for ($repo): ($e.msg)"
        exit 1
    }

    let new_version = (extract-github-version $latest.tag_name)
    if ($new_version | is-empty) {
        print -e $"Error: Could not extract version from tag ($latest.tag_name)"
        exit 1
    }

    let current_version = (extract-version $content)
    if ($current_version | is-empty) {
        print -e "Error: Could not find current version in default.nix"
        exit 1
    }

    print $"Current version: ($current_version)"
    print $"Latest version: ($new_version)"

    if $new_version == $current_version {
        print "Already up to date!"
        return
    }

    if $dry_run {
        print $"[dry-run] Would update ($package) to ($new_version)"
        return
    }

    let new_hash = match $fetcher {
        "fetchurl" | "fetchzip" => { prefetch-github-asset $content $current_version $new_version $latest $package },
        "fetchgit" => { prefetch-github-git $repo $latest.tag_name $package },
        _ => {
            print -e $"Error: Unsupported fetcher ($fetcher)"
            exit 1
        }
    }

    update-nix-file $default_nix $current_version $new_version $new_hash
    print $"Successfully updated ($package) from ($current_version) to ($new_version)"
}
```

- [ ] **Step 2: Add `prefetch-github-asset`**

```nu
def prefetch-github-asset [content: string, current_version: string, new_version: string, latest: record, package: string] {
    let url_match = ($content | parse -r 'url\s*=\s*"([^"]+)"')
    if ($url_match | is-empty) {
        print -e "Error: Could not find URL pattern in default.nix"
        exit 1
    }
    let url_pattern = $url_match.capture0.0

    let current_filename = ($url_pattern
        | str replace "v\${version}" $"v($current_version)"
        | str replace "\${version}" $current_version
        | path basename)

    let ext = if ($current_filename | str ends-with ".tar.gz") {
        ".tar.gz"
    } else {
        ($current_filename | path parse | get extension)
    }

    let candidates = ($latest.assets | where {|a|
        let name = $a.name
        let ext_match = if $ext == ".tar.gz" {
            ($name | str ends-with ".tar.gz")
        } else {
            ($name | str ends-with $ext)
        }
        let arch_match = ($name | str contains "x86_64") or ($name | str contains "amd64") or ($name | str contains "linux")
        $ext_match and $arch_match
    })

    let asset = if ($candidates | length) == 1 {
        ($candidates | first)
    } else {
        # Try exact filename substitution
        let expected_name = ($current_filename | str replace $current_version $new_version)
        let exact = ($latest.assets | where name == $expected_name | first)
        if ($exact | is-empty) {
            print -e $"Error: Could not find matching asset for ($package)"
            print $"Available assets: ($latest.assets | get name)"
            exit 1
        } else {
            $exact
        }
    }

    print $"Found asset: ($asset.name)"
    print $"Download URL: ($asset.browser_download_url)"

    print "Prefetching new version..."
    try {
        (nix-prefetch-url $asset.browser_download_url | str trim)
    } catch { |e|
        print -e $"Error: Failed to prefetch URL: ($e.msg)"
        exit 1
    }
}
```

- [ ] **Step 3: Add `prefetch-github-git`**

```nu
def prefetch-github-git [repo: string, tag: string, package: string] {
    print $"Prefetching git tag ($tag) for ($repo)..."
    try {
        (nix-prefetch-git --url $"https://github.com/($repo).git" --rev $tag | from json | get sha256)
    } catch { |e|
        print -e $"Error: Failed to prefetch git: ($e.msg)"
        exit 1
    }
}
```

- [ ] **Step 4: Update `main` dispatch to use `update-remote-package`**

In `update-one`, replace the `fetchurl` branch check with:

```nu
let fetcher = (get-fetcher-type $content)
if $fetcher == "local" {
    update-local-package $package $pkg_dir $default_nix $content $file
} else if $fetcher in ["fetchurl" "fetchzip" "fetchgit"] {
    update-remote-package $package $pkg_dir $default_nix $content $dry_run
} else {
    print -e $"Error: Unrecognized package type for ($package)"
    exit 1
}
```

- [ ] **Step 5: Verify with kimi-cli dry-run**

Run:

```bash
nu scripts/update-package.nu kimi-cli --dry-run
```

Expected: detects latest version and prints `[dry-run] Would update kimi-cli to 0.23.2` without modifying the file.

- [ ] **Step 6: Commit**

```bash
git add scripts/update-package.nu
git commit -m "feat(update-package): support fetchurl, fetchzip, fetchgit and scoped tags"
```

---

## Task 4: Add derivation validation with automatic revert

**Files:**
- Modify: `scripts/update-package.nu` (add validation helper and integrate into `update-remote-package`)

**Interfaces:**
- Consumes: `default_nix` path and original content.
- Produces: validated or reverted file.

- [ ] **Step 1: Add `validate-derivation` helper**

```nu
def validate-derivation [repo_root: path, package: string, default_nix: path, original_content: string] {
    let result = (do -i {
        nix-instantiate --eval --expr $"(with import \u003cnixpkgs\u003e { system = \"x86_64-linux\"; overlays = [ (import ($repo_root | path join "overlays.nix")) ]; }; ($package))" out> /dev/null
    } | complete)

    if $result.exit_code != 0 {
        print -e "Error: Derivation validation failed. Reverting file."
        print -e $result.stderr
        $original_content | save -f $default_nix
        false
    } else {
        true
    }
}
```

- [ ] **Step 2: Integrate validation into `update-remote-package`**

Before calling `update-nix-file`, capture the original content:

```nu
let original_content = $content
```

After `update-nix-file`, call:

```nu
if not (validate-derivation $repo_root $package $default_nix $original_content) {
    print -e $"Error: ($package) update reverted due to validation failure."
    exit 1
}
```

- [ ] **Step 3: Test validation by updating kimi-cli**

Run:

```bash
nu scripts/update-package.nu kimi-cli
```

Expected: version/hash updated, `nix-instantiate` succeeds, file kept.

- [ ] **Step 4: Commit**

```bash
git add scripts/update-package.nu
git commit -m "feat(update-package): validate derivations and revert on failure"
```

---

## Task 5: Implement `--all` bulk update loop

**Files:**
- Modify: `scripts/update-package.nu` (add `update-all` and `update-one` helpers)

**Interfaces:**
- Consumes: `repo_root`, `flake`, `dry_run`.
- Produces: updated package files and summary output.

- [ ] **Step 1: Add `update-one` helper**

```nu
def update-one [package: string, repo_root: path, dry_run: bool, file?: path] {
    let pkg_dir = ($repo_root | path join "packages" $package)

    if not ($pkg_dir | path exists) {
        print -e $"Error: Package directory does not exist: ($pkg_dir)"
        exit 1
    }

    let default_nix = ($pkg_dir | path join "default.nix")
    if not ($default_nix | path exists) {
        print -e $"Error: No default.nix found for package ($package)"
        exit 1
    }

    let content = (open $default_nix)
    let fetcher = (get-fetcher-type $content)

    if $fetcher == "local" {
        if ($file | is-empty) {
            print -e "Error: Please provide --file /path/to/new/binary"
            exit 1
        }
        update-local-package $package $pkg_dir $default_nix $content $file
    } else if $fetcher in ["fetchurl" "fetchzip" "fetchgit"] {
        update-remote-package $package $repo_root $pkg_dir $default_nix $content $dry_run
    } else {
        print -e $"Error: Unrecognized package type for ($package)"
        exit 1
    }
}
```

- [ ] **Step 2: Add `update-all` helper**

```nu
def update-all [repo_root: path, flake: bool, dry_run: bool] {
    let packages_dir = ($repo_root | path join "packages")
    let packages = (ls $packages_dir | where type == "dir" | get name | path basename)

    mut successes = []
    mut failures = []
    mut skipped = []

    for package in $packages {
        print $"\n--- ($package) ---"
        let default_nix = ($packages_dir | path join $package "default.nix")
        if not ($default_nix | path exists) {
            print $"Skipping ($package): no default.nix"
            $skipped = ($skipped | append $package)
            continue
        }

        let result = (do -i { update-one $package $repo_root $dry_run } | complete)

        if $result.exit_code != 0 {
            print -e $"Failed ($package): ($result.stderr)"
            $failures = ($failures | append $package)
        } else {
            $successes = ($successes | append $package)
        }
    }

    print "\n=== Summary ==="
    print $"Updated: ($successes | str join ', ')"
    print $"Failed: ($failures | str join ', ')"
    print $"Skipped: ($skipped | str join ', ')"

    if $flake and ($failures | is-empty) and not $dry_run {
        print "\nRunning nix flake update..."
        nix flake update $repo_root
    } else if $flake and $dry_run {
        print "[dry-run] Would run nix flake update"
    }

    if ($failures | is-not-empty) {
        exit 1
    }
}
```

- [ ] **Step 3: Test `--all --dry-run`**

Run:

```bash
nu scripts/update-package.nu --all --dry-run
```

Expected: iterates all packages, reports current/latest versions, no files modified.

- [ ] **Step 4: Commit**

```bash
git add scripts/update-package.nu
git commit -m "feat(update-package): add --all bulk update loop"
```

---

## Task 6: Final integration and edge-case fixes

**Files:**
- Modify: `scripts/update-package.nu`

**Interfaces:**
- Consumes: all prior helpers.
- Produces: final working script.

- [ ] **Step 1: Run `--all --dry-run` and fix any misclassified packages**

Run:

```bash
nu scripts/update-package.nu --all --dry-run
```

For each package that fails classification or asset matching, inspect its `default.nix` and adjust the regex/logic in `parse-github-repo`, `extract-github-version`, or `prefetch-github-asset` as needed. Common fixes:
- Tags without a semver-like prefix.
- Asset names that do not contain `x86_64`/`amd64`.
- URLs/homepages that point to non-GitHub sites.

- [ ] **Step 2: Test updating a representative set of packages**

Run on a few packages (e.g. `kimi-cli`, `carbonyl`, `windscribe`) without `--dry-run` and confirm each instantiates:

```bash
nu scripts/update-package.nu kimi-cli
nu scripts/update-package.nu carbonyl --dry-run
nu scripts/update-package.nu windscribe --dry-run
```

- [ ] **Step 3: Commit final fixes**

```bash
git add scripts/update-package.nu
git commit -m "fix(update-package): handle edge cases for package detection and asset matching"
```

---

## Self-review checklist

- [ ] Spec coverage: `--all`, `--flake`, `--dry-run`, `fetchzip`, `fetchgit`, scoped tags, validation, no commits.
- [ ] Placeholder scan: no TBD/TODO or vague steps.
- [ ] Type consistency: `update-one`, `update-remote-package`, `update-all` signatures match across tasks.

## Execution choice

Plan complete and saved to `docs/superpowers/plans/2026-07-08-automated-package-updates.md`.

Two execution options:

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — Execute tasks in this session using `executing-plans`, batch execution with checkpoints.

Which approach?
