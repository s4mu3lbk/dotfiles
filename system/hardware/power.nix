{
  config,
  pkgs,
  lib,
  ...
}: {
  options.power = {enable = lib.mkEnableOption "Power Management";};

  config = lib.mkIf config.power.enable {
    # TLP for advanced power management (charge thresholds are handled
    # separately by vendor-specific modules, e.g. asus_nb_wmi for ASUS)
    services.tlp = {
      enable = true;
      settings = {
        # CPU scaling governor
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # CPU energy performance preference
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # CPU boost
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # CPU HWP dynamic boost
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;

        # Platform profile
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        # Processor P-states
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 50;

        # NMI Watchdog
        NMI_WATCHDOG = 0;

        # SATA aggressive link power management
        SATA_LINKPWR_ON_AC = "med_power_with_dipm max_performance";
        SATA_LINKPWR_ON_BAT = "med_power_with_dipm min_power";

        # PCI Express Active State Power Management
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        # WiFi power saving
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # Disable wake on LAN
        WOL_DISABLE = "Y";

        # Sound power saving
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;

        # USB autosuspend
        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_AUDIO = 1;
        USB_EXCLUDE_BTUSB = 1;
        USB_EXCLUDE_PHONE = 0;
        USB_EXCLUDE_PRINTER = 1;
        USB_EXCLUDE_WWAN = 1;
      };
    };

    # Power Profiles Daemon (alternative/complementary to TLP)
    services.power-profiles-daemon.enable = false; # Disable to avoid conflicts with TLP

    # Thermald for Intel thermal management
    services.thermald.enable = config.hardware.cpu.intel.updateMicrocode or false;

    # Additional power management tools
    environment.systemPackages = with pkgs; [
      powertop
      acpi
    ];
  };
}
