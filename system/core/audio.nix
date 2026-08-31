{pkgs, ...}: {
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 512;
      };
    };

    extraConfig.pipewire-pulse."92-low-volume-fix" = {
      "pulse.properties" = {
        "pulse.min.req" = "32/48000";
        "pulse.default.tlength" = "32/48000";
      };
    };

    wireplumber.extraConfig = {
      "10-disable-hw-volume" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.*"; }
            ];
            actions = {
              update-props = {
                "api.alsa.soft-mixer" = true;
              };
            };
          }
        ];
      };
    };
  };

  systemd.services.alsa-hardware-setup = {
    description = "Configure ALSA Hardware State";
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
    path = [ pkgs.alsa-utils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      amixer -c 0 sset 'Auto-Mute Mode' Disabled || true
      amixer -c 0 sset Master 100% unmute || true
      amixer -c 0 sset Speaker 100% unmute || true
    '';
  };
}
