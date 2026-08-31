{
  description = "Samuel's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    viscus.url = "git+file:///home/samuel/Projects/self/viscus";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Private modules (VPN, work infra) — local-only flake, not published
    nixos-private.url = "git+file:///home/samuel/nixos-private";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen.url = "github:InioX/matugen?ref=v2.2.0";

    lf-icons = {
      url = "github:gokcehan/lf";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      home-manager,
      nixpkgs,
      ...
    }:
    let
      username = "samuel";
    in
    {
      # nixos config
      nixosConfigurations = {
        "nixos" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs username; };
          modules = [
            ./hosts/default/configuration.nix
            home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
            { networking.hostName = "nixos"; }
            {
              nixpkgs.overlays = [
                (import ./overlays.nix)
              ];
            }
          ];
        };

        # Headless server — see hosts/server/configuration.nix
        # TODO: set the real hostname
        "server" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs username; };
          modules = [
            ./hosts/server/configuration.nix
            home-manager.nixosModules.home-manager
            inputs.sops-nix.nixosModules.sops
            { networking.hostName = "server"; }
            {
              nixpkgs.overlays = [
                (import ./overlays.nix)
              ];
            }
          ];
        };
      };

      homeConfigurations = {
        "${username}" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
            overlays = [
              (import ./overlays.nix)
            ];
          };
          extraSpecialArgs = { inherit inputs username; };
          modules = [
            ({ pkgs, ... }: {
              imports = [
                inputs.sops-nix.homeManagerModules.sops
                ./home/home.nix
              ];
              nix.package = pkgs.nix;
              home = {
                username = username;
                homeDirectory = "/home/${username}";
              };
            })
          ];
        };
      };
    };
}
