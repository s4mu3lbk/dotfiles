{
  config,
  pkgs,
  lib,
  ...
}: {
  options.asus = {enable = lib.mkEnableOption "Asus Laptop";};

  config = lib.mkIf config.asus.enable {
    # ASUS battery charge limit (80%)
    boot.extraModprobeConfig = ''
      options asus_nb_wmi charge_control_end_threshold=80
    '';

    # openrgb
    services.hardware.openrgb.enable = true;

    # Make sure we're on a ≥6.9 kernel (24.11 defaults are fine; pin if needed)
    # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_11;

    # Intel iGPU stack (OpenGL, Vulkan, VA-API)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # Intel iHD VA-API driver
        vpl-gpu-rt # Intel VPL GPU runtime
        intel-compute-runtime # Intel OpenCL runtime
        vulkan-loader
        vulkan-tools
        libvdpau-va-gl # VDPAU driver for VA-API
        # intel-ocl-icd
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        intel-media-driver
        libvdpau-va-gl
      ];
    };

    boot.kernelParams = [
      "snd_hda_intel.power_save=0"
      "snd_hda_intel.power_save_controller=N"
      "i915.enable_guc=3"
      # Additional stability parameters for fullscreen video
      "i915.enable_psr=0" # Disable Panel Self Refresh (can cause black screens)
      "i915.enable_fbc=0" # Disable Frame Buffer Compression (can cause artifacts)
    ];


    # UX3405CA speaker fix: link correct firmware and configurations
    # hardware.firmware = [
    #   (pkgs.runCommand "ux3405ca-speaker-fix" {} ''
    #     mkdir -p $out/lib/firmware/cirrus
    #     cd $out/lib/firmware/cirrus
    #     # Link the DSP firmware
    #     ln -s cs35l41/v6.83.0/halo_cspl_RAM_revB2_29.85.0.wmfw.zst cs35l41-dsp1-spk-prot-10431a63-spkid0-r0.wmfw.zst
    #     ln -s cs35l41/v6.83.0/halo_cspl_RAM_revB2_29.85.0.wmfw.zst cs35l41-dsp1-spk-prot-10431a63-spkid0-l0.wmfw.zst
    #     # Link the tuning configurations
    #     ln -s cs35l41/bincfgs/cs35l41-dsp1-19_5dB.bincfg.zst cs35l41-dsp1-spk-prot-10431a63-spkid0-r0.bincfg.zst
    #     ln -s cs35l41/bincfgs/cs35l41-dsp1-19_5dB.bincfg.zst cs35l41-dsp1-spk-prot-10431a63-spkid0-l0.bincfg.zst
    #   '')
    # ];
  };
}
