#!/usr/bin/env nu

# Update custom packages in this dotfiles repository
# Usage: update-package <package-name> [--file <path-to-new-binary>]
#
# For fetchurl-based packages (carbonyl, windscribe), this checks GitHub releases
# and updates version + hash automatically.
# opencode-desktop is handled specially: the version-less stable deb from
# opencode.ai is downloaded and its version is read from the deb control file.
# For local binary packages (binance, antigravity, tradingview), provide --file.

def find-repo-root [] {
    # When installed via Nix, FILE_PWD points to the profile/bin directory,
    # not the dotfiles repo. Walk upward looking for flake.nix.
    mut dir = ($env.FILE_PWD? | default "/home/samuel/nixos-dotfiles/scripts")
    loop {
        let candidate = ($dir | path join "flake.nix" | path expand)
        if ($candidate | path exists) {
            return ($dir | path expand)
        }
        let parent = ($dir | path join ".." | path expand)
        if ($parent == ($dir | path expand)) {
            return "/home/samuel/nixos-dotfiles"
        }
        $dir = $parent
    }
}

def main [
    package?: string,
    --all,
    --flake,
    --dry-run,
    --file (-f): path
] {
    let repo_root = (find-repo-root)

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
        let result = (update-one $package $repo_root $dry_run $file)
        if $result.status == "err" {
            print -e $"Error: ($result.msg)"
            exit 1
        } else if $result.status == "skip" {
            print $"($result.msg)"
        }
    }
}

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

def extract-version [content: string] {
    let match = ($content | parse -r 'version\s*=\s*"([^"]+)"')
    if ($match | is-empty) {
        null
    } else {
        $match.capture0.0
    }
}

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

def extract-github-version [tag_name: string] {
    # Handle v1.2.3, 1.2.3, @scope/name@1.2.3, release-1.2.3
    let parsed = ($tag_name | parse -r '@?[^@]*@([0-9]+\.[0-9]+\.[0-9]+.*)')
    if ($parsed | is-not-empty) {
        $parsed.capture0.0
    } else {
        let simple = ($tag_name | parse -r '[._-]?v?([0-9]+\.[0-9]+\.[0-9]+.*)')
        if ($simple | is-empty) {
            null
        } else {
            $simple.capture0.0
        }
    }
}

def normalize-hash [hash: string, attr_name: string] {
    let is_sri = ($hash | str starts-with "sha256-")
    if ($attr_name | str contains "hash") {
        if $is_sri { $hash } else { (nix hash convert --hash-algo sha256 --to sri $hash | str trim) }
    } else {
        if $is_sri { (nix hash convert --hash-algo sha256 --to nix32 $hash | str trim) } else { $hash }
    }
}

def validate-derivation [repo_root: path, package: string, default_nix: path, original_content: string] {
    let overlays_path = ($repo_root | path join "overlays.nix" | into string)
    let nix_expr = "(let pkgs = import <nixpkgs> { system = \"x86_64-linux\"; overlays = [ (import " + $overlays_path + ") ]; }; in pkgs.\"" + $package + "\")"

    let result = (do -i {
        nix-instantiate --eval --expr $nix_expr
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

def update-remote-package [package: string, repo_root: path, pkg_dir: path, default_nix: path, content: string, dry_run: bool] {
    let fetcher = (get-fetcher-type $content)
    let repo = (parse-github-repo $content)

    if ($repo | is-empty) {
        return { status: "skip", msg: $"($package) is not a GitHub-based package; manual update required" }
    }

    print $"Checking GitHub releases for ($repo)..."

    let latest = try {
        http get $"https://api.github.com/repos/($repo)/releases/latest"
    } catch { |e|
        return { status: "err", msg: $"Failed to fetch releases for ($repo): ($e.msg)" }
    }

    let new_version = (extract-github-version $latest.tag_name)
    if ($new_version | is-empty) {
        return { status: "err", msg: $"Could not extract version from tag ($latest.tag_name)" }
    }

    let current_version = (extract-version $content)
    if ($current_version | is-empty) {
        return { status: "err", msg: "Could not find current version in default.nix" }
    }

    print $"Current version: ($current_version)"
    print $"Latest version: ($new_version)"

    if $dry_run {
        let selection = (select-github-asset $content $current_version $new_version $latest $package)
        if $selection.status == "err" {
            return $selection
        }
        let asset = $selection.asset
        print $"[dry-run] Asset URL: ($asset.browser_download_url)"
        if $new_version == $current_version {
            print "Already up to date!"
            return { status: "uptodate" }
        } else {
            print $"[dry-run] Would update ($package) to ($new_version)"
            return { status: "ok" }
        }
    }

    if $new_version == $current_version {
        print "Already up to date!"
        return { status: "uptodate" }
    }

    let prefetch_result = match $fetcher {
        "fetchurl" | "fetchzip" => { prefetch-github-asset $content $current_version $new_version $latest $package },
        "fetchgit" => { prefetch-github-git $repo $latest.tag_name $package },
        _ => { status: "err", msg: $"Unsupported fetcher ($fetcher)" }
    }

    if $prefetch_result.status == "err" {
        return $prefetch_result
    }
    let new_hash = $prefetch_result.hash

    let original_content = $content
    update-nix-file $default_nix $current_version $new_version $new_hash

    if not (validate-derivation $repo_root $package $default_nix $original_content) {
        return { status: "err", msg: $"($package) update reverted due to validation failure." }
    }

    print $"Successfully updated ($package) from ($current_version) to ($new_version)"
    { status: "ok" }
}

# opencode-desktop fetches a version-less stable deb from opencode.ai, so the
# GitHub-release path cannot handle it. Download the deb and read the version
# out of its control file instead.
def update-opencode-deb [package: string, repo_root: path, default_nix: path, content: string, dry_run: bool] {
    let url_match = ($content | parse -r 'url\s*=\s*"([^"]+)"')
    if ($url_match | is-empty) {
        return { status: "err", msg: "Could not find URL pattern in default.nix" }
    }
    let url = $url_match.capture0.0

    let current_version = (extract-version $content)
    if ($current_version | is-empty) {
        return { status: "err", msg: "Could not find current version in default.nix" }
    }

    let tmp_deb = (mktemp --suffix ".deb" | str trim)
    print $"Downloading ($url)..."
    try {
        http get $url | save -f $tmp_deb
    } catch { |e|
        rm -f $tmp_deb
        return { status: "err", msg: $"Failed to download ($url): ($e.msg)" }
    }

    # A .deb is an ar archive; the version lives in control.tar.{gz,xz,zst}
    let control_members = (ar t $tmp_deb | lines | where {|m| $m | str starts-with "control.tar" })
    if ($control_members | is-empty) {
        rm -f $tmp_deb
        return { status: "err", msg: "No control.tar member found in deb" }
    }
    let control_member = ($control_members | first)
    # tar does not auto-detect compression when reading from stdin
    let decompress_flag = if ($control_member | str ends-with ".gz") {
        "-z"
    } else if ($control_member | str ends-with ".zst") {
        "--zstd"
    } else {
        "-J"
    }
    let control_text = (ar p $tmp_deb $control_member | tar xOf - $decompress_flag ./control)
    let parsed = ($control_text | parse -r 'Version:\s*(\S+)')
    if ($parsed | is-empty) {
        rm -f $tmp_deb
        return { status: "err", msg: "Could not extract version from deb control file" }
    }
    let new_version = $parsed.capture0.0

    print $"Current version: ($current_version)"
    print $"Latest version: ($new_version)"

    if $dry_run {
        rm -f $tmp_deb
        if $new_version == $current_version {
            print "Already up to date!"
            return { status: "uptodate" }
        } else {
            print $"[dry-run] Would update ($package) to ($new_version)"
            return { status: "ok" }
        }
    }

    if $new_version == $current_version {
        rm -f $tmp_deb
        print "Already up to date!"
        return { status: "uptodate" }
    }

    let new_hash = (nix hash file --sri $tmp_deb | str trim)
    rm -f $tmp_deb

    let original_content = $content
    update-nix-file $default_nix $current_version $new_version $new_hash

    if not (validate-derivation $repo_root $package $default_nix $original_content) {
        return { status: "err", msg: $"($package) update reverted due to validation failure." }
    }

    print $"Successfully updated ($package) from ($current_version) to ($new_version)"
    { status: "ok" }
}

def select-github-asset [content: string, current_version: string, new_version: string, latest: record, package: string] {
    let url_match = ($content | parse -r 'url\s*=\s*"([^"]+)"')
    if ($url_match | is-empty) {
        return { status: "err", msg: "Could not find URL pattern in default.nix" }
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
            let available = ($latest.assets | get name | str join ", ")
            return { status: "err", msg: $"Could not find matching asset for ($package). Available assets: ($available)" }
        } else {
            $exact
        }
    }

    { status: "ok", asset: $asset }
}

def prefetch-github-asset [content: string, current_version: string, new_version: string, latest: record, package: string] {
    let fetcher = (get-fetcher-type $content)
    let selection = (select-github-asset $content $current_version $new_version $latest $package)
    if $selection.status == "err" {
        return $selection
    }
    let asset = $selection.asset

    print $"Found asset: ($asset.name)"
    print $"Download URL: ($asset.browser_download_url)"

    print "Prefetching new version..."
    let prefetch_args = if $fetcher == "fetchzip" {
        [$asset.browser_download_url "--unpack"]
    } else {
        [$asset.browser_download_url]
    }
    let hash = try {
        (nix-prefetch-url ...$prefetch_args | str trim)
    } catch { |e|
        return { status: "err", msg: $"Failed to prefetch URL: ($e.msg)" }
    }

    { status: "ok", hash: $hash }
}

def prefetch-github-git [repo: string, tag: string, package: string] {
    print $"Prefetching git tag ($tag) for ($repo)..."
    let hash = try {
        (nix-prefetch-git --url $"https://github.com/($repo).git" --rev $tag | from json | get sha256)
    } catch { |e|
        return { status: "err", msg: $"Failed to prefetch git: ($e.msg)" }
    }
    { status: "ok", hash: $hash }
}

def update-local-package [package: string, pkg_dir: path, default_nix: path, content: string, file?: path] {
    if ($file | is-empty) {
        return { status: "skip", msg: $"($package) is a local package; provide --file to update" }
    }

    if not ($file | path exists) {
        return { status: "err", msg: $"File does not exist: ($file)" }
    }

    let current_version_match = ($content | parse -r 'version\s*=\s*"([^"]+)"')
    let current_version = $current_version_match.capture0.0
    print $"Current version: ($current_version)"
    
    # Get new version from user
    let new_version = (input "Enter new version: ")
    
    if ($new_version | is-empty) {
        return { status: "err", msg: "Version cannot be empty" }
    }
    
    # Find the src file pattern
    let src_match = ($content | parse -r 'src\s*=\s*\./([^;\s]+)')
    if ($src_match | is-empty) {
        return { status: "err", msg: "Could not find local src file pattern" }
    }
    let src_pattern = $src_match.capture0.0
    let dest_file = ($pkg_dir | path join $src_pattern)
    
    # Copy the new file
    print $"Copying ($file) to ($dest_file)..."
    cp -f $file $dest_file
    
    # Update version in default.nix
    update-nix-file $default_nix $current_version $new_version
    
    print $"Successfully updated ($package) to ($new_version)"
    print "Next steps:"
    print $"  1. Test the build: nix-build -E 'with import <nixpkgs> {}; callPackage ($pkg_dir) {}'"
    print "  2. Commit the changes"
    { status: "ok" }
}

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

def update-one [package: string, repo_root: path, dry_run: bool, file?: path] {
    let pkg_dir = ($repo_root | path join "packages" $package)

    if not ($pkg_dir | path exists) {
        return { status: "err", msg: $"Package directory does not exist: ($pkg_dir)" }
    }

    let default_nix = ($pkg_dir | path join "default.nix")
    if not ($default_nix | path exists) {
        return { status: "err", msg: $"No default.nix found for package ($package)" }
    }

    let content = (open $default_nix)
    let fetcher = (get-fetcher-type $content)

    if $fetcher == "local" {
        update-local-package $package $pkg_dir $default_nix $content $file
    } else if $fetcher in ["fetchurl" "fetchzip" "fetchgit"] {
        # if ($content | str contains "opencode.ai/download") {
        #     update-opencode-deb $package $repo_root $default_nix $content $dry_run
        # } else {
        update-remote-package $package $repo_root $pkg_dir $default_nix $content $dry_run
        # }
    } else {
        { status: "skip", msg: $"($package) has an unrecognized package type" }
    }
}

def update-all [repo_root: path, flake: bool, dry_run: bool] {
    let packages_dir = ($repo_root | path join "packages")
    let packages = (ls $packages_dir | where type == "dir" | get name | path basename)

    mut successes = []
    mut uptodate = []
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

        let result = (update-one $package $repo_root $dry_run)

        if $result.status == "err" {
            print -e $"Failed ($package): ($result.msg)"
            $failures = ($failures | append $package)
        } else if $result.status == "skip" {
            print $"Skipping ($package): ($result.msg)"
            $skipped = ($skipped | append $package)
        } else if $result.status == "uptodate" {
            print $"Up-to-date: ($package)"
            $uptodate = ($uptodate | append $package)
        } else {
            $successes = ($successes | append $package)
        }
    }

    print "\n=== Summary ==="
    print $"Updated: ($successes | str join ', ')"
    print $"Up-to-date: ($uptodate | str join ', ')"
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
