{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, acl
, libx11
, libxcb
, libxext
, libxrandr
, libxcomposite
, libxdamage
, libxfixes
, xcbutilcursor
, xcbutilwm
, xcbutilimage
, xcbutilkeysyms
, xcbutilrenderutil
, libxkbcommon
, wayland
, libglvnd
, glib
, freetype
, fontconfig
, harfbuzz
, zstd
, pcre2
, brotli
, libdrm
, gtk3
, pango
, cairo
, alsa-lib
, nss
, nspr
, systemd
, libnl
, libcap_ng
, nftables
, dbus
, iproute2
, util-linux
}:

stdenv.mkDerivation rec {
  pname = "windscribe";
  version = "2.24.13";

  src = fetchurl {
    url = "https://github.com/Windscribe/Desktop-App/releases/download/v${version}/windscribe_${version}_amd64.deb";
    sha256 = "148rrv5hmjq405sak45w1y2f79kxmglxmk1i5f6qx1bwrxzz3abr";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    acl
    libx11
    libxcb
    libxext
    libxrandr
    libxcomposite
    libxdamage
    libxfixes
    libxkbcommon
    wayland
    libglvnd
    glib
    freetype
    fontconfig
    harfbuzz
    zstd
    pcre2
    brotli
    libdrm
    stdenv.cc.cc.lib
    gtk3
    pango
    cairo
    alsa-lib
    nss
    nspr
    systemd
    libnl
    libcap_ng
    nftables
    xcbutilcursor
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    dbus
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/opt
    
    cp -r opt/windscribe $out/opt/
    cp -r usr/share $out/
    
    if [ -d usr/polkit-1 ]; then
      cp -r usr/polkit-1 $out/share/
    fi

    # Create interactive shell binaries, wrapping them using our fake payload to intercept setgid
    # We do this because granting CAP_SETGID would activate glibc's AT_SECURE mode, stripping 
    # important environment variables (like LIBGL_DRIVERS_PATH) and heavily breaking Wayland/Mesa.
    mkdir -p $out/lib
    echo '#define _GNU_SOURCE' > fakesetgid.c
    echo '#include <unistd.h>' >> fakesetgid.c
    echo '#include <string.h>' >> fakesetgid.c
    echo '#include <dlfcn.h>' >> fakesetgid.c
    echo '#include <spawn.h>' >> fakesetgid.c
    echo 'int setgid(gid_t gid) { return 0; }' >> fakesetgid.c
    echo 'static const char* map_path(const char* path) {' >> fakesetgid.c
    echo '  if (path && strcmp(path, "/usr/bin/pkexec") == 0) return "/run/wrappers/bin/pkexec";' >> fakesetgid.c
    echo '  if (path && strcmp(path, "/usr/bin/resolvconf") == 0) return "/run/current-system/sw/bin/resolvconf";' >> fakesetgid.c
    echo '  return path;' >> fakesetgid.c
    echo '}' >> fakesetgid.c
    echo 'typedef int (*execve_func_t)(const char*, char* const[], char* const[]);' >> fakesetgid.c
    echo 'int execve(const char *pathname, char *const argv[], char *const envp[]) {' >> fakesetgid.c
    echo '  execve_func_t orig = (execve_func_t)dlsym(RTLD_NEXT, "execve");' >> fakesetgid.c
    echo '  if (argv && argv[0]) ((char**)argv)[0] = (char*)map_path(argv[0]);' >> fakesetgid.c
    echo '  return orig(map_path(pathname), argv, envp);' >> fakesetgid.c
    echo '}' >> fakesetgid.c
    echo 'typedef int (*execvp_func_t)(const char*, char* const[]);' >> fakesetgid.c
    echo 'int execvp(const char *file, char *const argv[]) {' >> fakesetgid.c
    echo '  execvp_func_t orig = (execvp_func_t)dlsym(RTLD_NEXT, "execvp");' >> fakesetgid.c
    echo '  if (argv && argv[0]) ((char**)argv)[0] = (char*)map_path(argv[0]);' >> fakesetgid.c
    echo '  return orig(map_path(file), argv);' >> fakesetgid.c
    echo '}' >> fakesetgid.c
    echo 'typedef int (*posix_spawn_func_t)(pid_t*, const char*, const posix_spawn_file_actions_t*, const posix_spawnattr_t*, char* const[], char* const[]);' >> fakesetgid.c
    echo 'int posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]) {' >> fakesetgid.c
    echo '  posix_spawn_func_t orig = (posix_spawn_func_t)dlsym(RTLD_NEXT, "posix_spawn");' >> fakesetgid.c
    echo '  if (argv && argv[0]) ((char**)argv)[0] = (char*)map_path(argv[0]);' >> fakesetgid.c
    echo '  return orig(pid, map_path(path), file_actions, attrp, argv, envp);' >> fakesetgid.c
    echo '}' >> fakesetgid.c
    echo 'typedef int (*posix_spawnp_func_t)(pid_t*, const char*, const posix_spawn_file_actions_t*, const posix_spawnattr_t*, char* const[], char* const[]);' >> fakesetgid.c
    echo 'int posix_spawnp(pid_t *pid, const char *file, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]) {' >> fakesetgid.c
    echo '  posix_spawnp_func_t orig = (posix_spawnp_func_t)dlsym(RTLD_NEXT, "posix_spawnp");' >> fakesetgid.c
    echo '  if (argv && argv[0]) ((char**)argv)[0] = (char*)map_path(argv[0]);' >> fakesetgid.c
    echo '  return orig(pid, map_path(file), file_actions, attrp, argv, envp);' >> fakesetgid.c
    echo '}' >> fakesetgid.c
    # The helper does setenv("PATH", "/usr/sbin:/usr/bin:/sbin:/bin", 1) at startup, which
    # wipes out the unit's Environment=PATH and leaves every shelled-out command (ip, grep,
    # awk, busctl, ...) unfindable on NixOS. Ignore PATH overrides so the systemd PATH survives.
    echo 'typedef int (*setenv_func_t)(const char*, const char*, int);' >> fakesetgid.c
    echo 'int setenv(const char *name, const char *value, int overwrite) {' >> fakesetgid.c
    echo '  if (name && strcmp(name, "PATH") == 0) return 0;' >> fakesetgid.c
    echo '  setenv_func_t orig = (setenv_func_t)dlsym(RTLD_NEXT, "setenv");' >> fakesetgid.c
    echo '  return orig(name, value, overwrite);' >> fakesetgid.c
    echo '}' >> fakesetgid.c
    $CC -shared -fPIC -ldl -o $out/lib/libfakesetgid.so fakesetgid.c

    makeWrapper $out/opt/windscribe/Windscribe $out/bin/windscribe \
      --set LD_PRELOAD "$out/lib/libfakesetgid.so" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ dbus ]}"
      
    makeWrapper $out/opt/windscribe/windscribe-cli $out/bin/windscribe-cli \
      --set LD_PRELOAD "$out/lib/libfakesetgid.so" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ dbus ]}"

    substituteInPlace $out/share/applications/windscribe.desktop \
      --replace "/opt/windscribe/Windscribe" "$out/bin/windscribe"

    # Rename bundled OpenSSL to avoid SONAME conflict with Nixpkgs (pulled by systemd in AT_SECURE mode)
    mv $out/opt/windscribe/lib/libssl.so.4 $out/opt/windscribe/lib/libws_ssl.so.4
    mv $out/opt/windscribe/lib/libcrypto.so.4 $out/opt/windscribe/lib/libws_crypto.so.4

    patchelf --set-soname libws_ssl.so.4 $out/opt/windscribe/lib/libws_ssl.so.4
    patchelf --set-soname libws_crypto.so.4 $out/opt/windscribe/lib/libws_crypto.so.4

    find $out/opt/windscribe -type f | while read -r f; do
      if patchelf --print-needed "$f" >/dev/null 2>&1; then
        if patchelf --print-needed "$f" | grep -q "^libssl\.so\.4$"; then
          patchelf --replace-needed libssl.so.4 libws_ssl.so.4 "$f"
        fi
        if patchelf --print-needed "$f" | grep -q "^libcrypto\.so\.4$"; then
          patchelf --replace-needed libcrypto.so.4 libws_crypto.so.4 "$f"
        fi
      fi
    done
    # Patch update-systemd-resolved:
    # 1. Add NixOS paths so the script can find ip, logger, busctl, resolvectl
    #    (OpenVPN spawns it as a subprocess without the helper's PATH)
    # 2. Map OpenVPN 2.6+ script_type values (init/restart) → up
    substituteInPlace $out/opt/windscribe/scripts/update-systemd-resolved \
      --replace 'PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"' \
        'PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin:${iproute2}/bin:${util-linux}/bin:${systemd}/bin"' \
      --replace 'main "''${script_type:-down}" "$@"' \
        '_st="''${script_type:-down}"; case "$_st" in init|restart) _st=up;; esac; main "$_st" "$@"'


  '';

  meta = with lib; {
    description = "Windscribe VPN desktop application";
    homepage = "https://windscribe.com";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}
