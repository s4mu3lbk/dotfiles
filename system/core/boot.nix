# Bootloader, kernel, sysctl, filesystem support, and systemd boot config
{pkgs, ...}: {
  boot = {
    # AppImage support
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = "\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\xff\\xff\\xff";
      magicOrExtension = "\\x7fELF....AI\\x02";
    };

    tmp.cleanOnBoot = true;
    supportedFilesystems = ["ntfs"];

    loader = {
      timeout = 5;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = true;
    };

    # Boot logs
    consoleLogLevel = 4;
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "boot.shell_on_fail"
      "rd.systemd.show_status=true"
      "systemd.show_status=true"
      "vt.global_cursor_default=1"
    ];

    # Performance tuning
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "fs.inotify.max_user_instances" = 256;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  # Firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # Systemd boot behaviour
  systemd.services."systemd-udev-settle".enable = false;
  systemd.services."NetworkManager-wait-online".enable = false;
  systemd.network.wait-online.enable = false;

  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = ["fuse" "configfs"];

  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "10s";
      DefaultStandardOutput = "journal";
      DefaultStandardError = "journal";
      LogLevel = "warning";
    };
  };

  system.stateVersion = "26.05";
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
}
