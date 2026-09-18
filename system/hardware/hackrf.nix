# HackRF SDR: CLI tools (hackrf_info, hackrf_transfer, ...) + udev rules for non-root access
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hackrf = {enable = lib.mkEnableOption "HackRF SDR";};

  config = lib.mkIf config.hackrf.enable {
    hardware.hackrf.enable = true;

    # CLI tools (hackrf_info, hackrf_transfer, ...) — hardware.hackrf only adds udev rules
    environment.systemPackages = [pkgs.hackrf];
  };
}
