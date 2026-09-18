# System services: smart cards, xserver, printing, flatpak, openssh, logind
{pkgs, ...}: let
  monitor-graphics = pkgs.writeShellScriptBin "monitor-graphics"
    (builtins.readFile ../../scripts/monitor-graphics.sh);
  webEidPolicy = builtins.toJSON {
    ExtensionInstallForcelist = [
      "ncibgoaomkmdpilpocfeponihegamlic" # Web eID extension
    ];
  };
in {
  # Smart‑card (EstEID) — PKCS#11 module + daemon
  environment.etc."pkcs11/modules/opensc-pkcs11".text = ''
    module: ${pkgs.opensc}/lib/opensc-pkcs11.so
  '';

  # Web eID — native messaging host + extension autoinstall (Chrome, Vivaldi)
  environment.etc."opt/chrome/native-messaging-hosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/etc/opt/chrome/native-messaging-hosts/eu.webeid.json";
  # Vivaldi uses the shared Chromium NMH dir and its own policy dir
  # (verified against vivaldi-bin strings)
  environment.etc."chromium/native-messaging-hosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/etc/chromium/native-messaging-hosts/eu.webeid.json";
  environment.etc."opt/chrome/policies/managed/web-eid.json".text = webEidPolicy;
  environment.etc."vivaldi/policies/managed/web-eid.json".text = webEidPolicy;

  services = {
    # Smart‑card daemon
    pcscd = {
      enable = true;
      plugins = [
        pkgs.ccid
        pkgs.acsccid
      ];
    };

    udev.packages = with pkgs; [steam-devices-udev-rules];
    libinput.enable = true;

    xserver = {
      enable = true;
      excludePackages = [pkgs.xterm];
    };

    printing.enable = true;
    flatpak.enable = true;

    # SSH — hardened: key-based auth only, no root login
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  # Logind
  services.logind.settings = {
    Login = {
      HandlePowerKey = "ignore";
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
    };
  };

  # Graphics health check timer
  systemd.timers.graphics-health-check = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  systemd.services.graphics-health-check = {
    script = ''
      ${monitor-graphics}/bin/monitor-graphics >> /var/log/graphics-health.log 2>&1
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "samuel";
    };
  };
}
