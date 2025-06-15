{
  description = "Ari's NixOS config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirks
    hardware.url = "github:nixos/nixos-hardware";

    # Nh
    nh = {
      url = "github:nix-community/nh/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Helix
    helix = {
      url = "github:helix-editor/helix/25.01";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust devshell
    rust-devshell = {
      url = "path:./devshells/rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zellij statusbar
    zjstatus.url = "github:dj95/zjstatus";

    # Zellij quit prompt
    zj-quit = {
      url = "path:./flakes/zj-quit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets & encryption
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs = { nixpkgs, unstable, nix-darwin, home-manager, agenix, rust-devshell, ... }@inputs:
    let
      homeConfig = { module, system ? "x86_64-linux" }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs; };
        modules = [ module ];
      };
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = function: nixpkgs.lib.genAttrs supportedSystems function;
      pkgsFor = system: import nixpkgs {
        inherit system;
      };
    in
    {
      nixosConfigurations = {
        ari = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./system/desktop/configuration.nix
          ];
        };

        cloud-dev = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./system/server/configuration.nix
          ];
        };
      };

      darwinConfigurations."Aris-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          agenix.darwinModules.default
          home-manager.darwinModules.home-manager
          ./system/macbook/configuration.nix
        ];
      };

      homeConfigurations = {
        "ari@ari" = homeConfig { module = ./home/pc.nix; };
        "ari@Aris-MacBook-Pro" = homeConfig { module = ./home/macbook.nix; system = "x86_64-darwin"; };
      };

      devShells = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          rust = rust-devshell.devShells.${system}.default;
        }
      );
    };
}
