# Nix daemon settings, nixpkgs config, and nix-ld
{pkgs, ...}: {
  documentation.nixos.enable = false; # .desktop

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "pnpm-10.34.0"
      "electron-39.8.10"
    ];
  };

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Needed for neovim mason binaries
  programs.nix-ld = {
    enable = true;
    # Runtime deps for unpatched Electron apps installed outside nixpkgs
    # (e.g. terminal-browser from terminal-browser.sh)
    libraries = with pkgs; [
      alsa-lib
      atk
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libxcb
      libxkbcommon
      libglvnd # libGL.so.1, libEGL.so.1
      libXrandr
      libgbm # libgbm.so.1 (split out of mesa in recent nixpkgs)
      nspr
      nss
      pango
      systemdLibs # libudev.so.1
    ];
  };

  # Shells
  programs.fish.enable = true;
  environment.shells = with pkgs; [fish nushell];

  # dconf (required by many GTK/GNOME apps)
  programs.dconf.enable = true;

  # XDG portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = "*";
      };
    };
  };
}
