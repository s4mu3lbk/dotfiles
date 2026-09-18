# Server host — headless. Imports only server-relevant core modules
# (no DE, audio, bluetooth, fonts, howdy, or desktop services).
{
  inputs,
  username,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware.nix

    # Core modules (server-relevant subset of ../../system)
    ../../system/core/nix.nix
    ../../system/core/boot.nix
    ../../system/core/networking.nix
    ../../system/core/locale.nix
    ../../system/core/virtualisation.nix

    # Desktop environments (inert unless enabled — see specialisation below)
    ../../system/de/cosmic.nix

    # Private modules (VPN, work infra) — from the local nixos-private flake
    inputs.nixos-private.nixosModules.networking

    # Always-on Windscribe VPN (server only) — from the local nixos-private flake
    inputs.nixos-private.nixosModules.server-vpn
  ];

  # sops targets for the private networking module's VPN secrets
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/samuel/.config/sops/age/keys.txt";

  # COSMIC desktop as an opt-in specialisation — boot into it via the
  # bootloader entry or `sudo /run/current-system/specialisation/cosmic/bin/switch-to-configuration switch`
  specialisation.cosmic.configuration = {
    imports = [
      # Excluded from the server's base imports; needed for a usable desktop
      ../../system/core/audio.nix
      ../../system/core/fonts.nix
    ];

    system.nixos.tags = ["cosmic"];
    cosmic.enable = true;
  };

  # SSH — hardened: key-based auth only, no root login
  # (inlined here because system/core/services.nix is desktop-oriented)
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    initialPassword = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICe5ofCQbg+6fl0FQ7YpVsb+zZ3HSsZzptG+2s4aJ6RW samuel@nixos"
    ];
  };

  # TODO: rename `newuser` to the real username and add their SSH public key
  users.users.morph = {
    isNormalUser = true;
    initialPassword = "morph";
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... newuser@host"
    ];
  };

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs username; };
    users.${username} = {
      home.username = username;
      home.homeDirectory = "/home/${username}";
      imports = [
        inputs.sops-nix.homeManagerModules.sops
        ../../home/server.nix

        # Private HM modules — from the local nixos-private flake
        inputs.nixos-private.homeModules.bitbucket-env
        inputs.nixos-private.homeModules.vault
      ];
    };
  };
}
