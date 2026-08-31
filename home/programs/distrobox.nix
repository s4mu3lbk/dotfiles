{ pkgs, ... }:
let
  inherit (builtins) concatStringsSep filter typeOf;
  inherit (import ../../scripts pkgs) box;
  nvim = import ../../packages/nvim { inherit pkgs; };

  mkBox = name:
    { image, exec ? "${pkgs.nushell}/bin/nu", packages ? [ ], }:
    let
      distropkgs = concatStringsSep " " (filter (p: typeOf p == "string")
        (packages ++ [ "wl-clipboard" "git" ]));

      path = [
        "/bin"
        "/sbin"
        "/usr/bin"
        "/usr/sbin"
        "/usr/local/bin"
        "$HOME/.local/bin"
      ] ++ [ "${nvim}/bin" "${pkgs.nushell}/bin" ]
        ++ (map (p: "${p}/bin") (filter (p: typeOf p == "set") packages));

      db-exec = pkgs.writeShellScript "db-exec" ''
        export XDG_DATA_DIRS="/usr/share:/usr/local/share"
        export PATH="${builtins.concatStringsSep ":" path}"
        if [ $# -eq 0 ]; then ${exec}; else bash -c "$@"; fi
      '';
    in pkgs.writeShellScriptBin name ''
      ${box} ${name} ${image} ${db-exec} $@ --pkgs "${distropkgs}"
    '';
in {
  home.packages = [
    pkgs.distrobox
    (mkBox "ubuntu" { image = "quay.io/toolbx/ubuntu-toolbox:latest"; })
    (mkBox "fedora" {
      image = "registry.fedoraproject.org/fedora-toolbox:rawhide";
      packages = [
        "gcc poetry python-devel mysql-devel pango-devel nodejs npm cargo"
        pkgs.lazygit
      ];
    })
    (mkBox "alpine" { image = "docker.io/library/alpine:latest"; })
    # NOTE: the kali box is created manually, not via this wrapper — distrobox's
    # host /tmp bind mount breaks Kali's systemd/tpm-udev postinst during init.
    # To recreate: distrobox create --dry-run with the same args, replace
    # `--volume /tmp:/tmp:rslave` with `--tmpfs /tmp:rw,nosuid,nodev,exec`, and add
    # --pre-init-hooks "mkdir -p /etc/tmpfiles.d && touch /etc/tmpfiles.d/tpm-udev.conf"
    (mkBox "kali" {
      image = "docker.io/kalilinux/kali-rolling:latest";
      packages = [ "kali-tools-top10" ];
    })
    # Rootful kali for raw-socket work (nmap -sS, ARP scans, etc.).
    # Created manually with: distrobox create --root --name kali-root ...
    # (real root avoids the rootless /tmp postinst issues above)
    (pkgs.writeShellScriptBin "kali-root" ''
      if [ $# -eq 0 ]; then
        exec distrobox enter --root kali-root
      else
        exec distrobox enter --root kali-root -- bash -c "$*"
      fi
    '')
    (mkBox "arch" {
      image = "docker.io/library/alpine:latest";
      packages = let
        yay = pkgs.writeShellScriptBin "yay" ''
          if [[ ! -f /bin/yay ]]; then
            tmpdir="$HOME/.yay-bin"
            if [[ -d "$tmpdir" ]]; then sudo rm -r "$tmpdir"; fi
            git clone https://aur.archlinux.org/yay-bin.git "$tmpdir"
            cd "$tmpdir"
            makepkg -si
            sudo rm -r "$tmpdir"
          fi
          /bin/yay $@
        '';
      in [ "base-devel" yay ];
    })
  ];
}
