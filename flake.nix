{
  description = "Samuel's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    viscus.url = "git+ssh://git@github.com/s4mu3lbk/viscus.git";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Private modules (VPN, work infra) — private GitHub repo
    nixos-private.url = "git+ssh://git@github.com/s4mu3lbk/dotfiles-private.git";

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

    # Patched cosmic-comp with wlr-gamma-control (night light) support.
    # Local checkout at /home/samuel/Projects/self/cosmic-epoch/cosmic-comp.
    # NOTE: git+file inputs only include tracked files and require a CLEAN tree —
    # commit your changes there, then `nix flake lock --update-input cosmic-comp-patch`.
    cosmic-comp-patch = {
      url = "git+file:///home/samuel/Projects/self/cosmic-epoch/cosmic-comp";
      flake = false;
    };

    # Local Linux port of the Kimi desktop app (Kimi Work).
    # Local checkout at /home/samuel/Projects/self/kimi-work.
    # NOTE: git+file inputs only include tracked files and require a CLEAN tree —
    # commit your changes there, then `nix flake lock --update-input kimi-work`.
    kimi-work = {
      url = "git+file:///home/samuel/Projects/self/kimi-work";
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
                (import ./overlays.nix { inherit inputs; })
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
                (import ./overlays.nix { inherit inputs; })
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
              (import ./overlays.nix { inherit inputs; })
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
