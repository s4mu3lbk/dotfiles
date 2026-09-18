# System-level packages: core tools, smart-card utilities, media codecs, GStreamer
{pkgs, inputs, ...}: {
  environment.systemPackages = with pkgs; [
    inputs.viscus.packages.${pkgs.system}.default

    # Smart-card / DigiDoc
    qdigidoc
    p11-kit
    opensc
    pcsc-tools
    web-eid-app
    nvtopPackages.intel

    # Core tools
    sops
    podman-compose
    freerdp
    git
    wget
    # open-webui

    # Video / VA-API diagnostics
    libva-utils
    ffmpeg-full

    # GStreamer plugins (required for Chromium-based browsers)
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-rs

    # Codecs
    x264
    x265
    libaom
    libvpx

    # VA-API
    libva

    # Vivaldi codec support
    vivaldi-ffmpeg-codecs
    libxcb

    # Android Debug Bridge (adb/fastboot)
    android-tools
  ];
}
