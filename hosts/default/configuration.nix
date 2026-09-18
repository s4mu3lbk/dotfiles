{
  inputs,
  lib,
  username,
  ...
}:
{
  imports = [
    ./hardware.nix

    # System modules (core: nix, boot, networking, services, etc.)
    ../../system

    # Hardware
    ../../system/hardware/asus.nix
    ../../system/hardware/power.nix
    ../../system/hardware/hackrf.nix

    # Desktop environments
    ../../system/de/kde.nix
    ../../system/de/cosmic.nix

    # Private modules (VPN, work infra) — from the local nixos-private flake
    inputs.nixos-private.nixosModules.networking
  ];

  # sops targets for the private networking module's VPN secrets
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/home/samuel/.config/sops/age/keys.txt";

  # Default Desktop Environment
  kde.enable = lib.mkDefault true;
  cosmic.enable = lib.mkDefault false;

  specialisation = {

    cosmic.configuration = {
      system.nixos.tags = [ "cosmic" ];
      cosmic.enable = lib.mkForce true;
      kde.enable = lib.mkForce false;
    };
  };

  asus.enable = true;

  power.enable = true;

  hackrf.enable = true;

  hardware.uinput.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    initialPassword = username;
    extraGroups = [
      "uinput"
      "nixosvmtest"
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "libvirtd"
      "docker"
      "windscribe"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICe5ofCQbg+6fl0FQ7YpVsb+zZ3HSsZzptG+2s4aJ6RW samuel@nixos"
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
        ../../home/home.nix

        # Private HM modules — from the local nixos-private flake
        inputs.nixos-private.homeModules.bitbucket-env
        inputs.nixos-private.homeModules.opencode-bitbucket
        inputs.nixos-private.homeModules.vault
      ];
    };
  };
}
