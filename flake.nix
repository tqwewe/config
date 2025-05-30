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

    # niri.url = "github:sodiboo/niri-flake";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprlock.url = "github:hyprwm/hyprlock";
    # ashell.url = "github:MalpenZibo/ashell";
    ashell = {
      type = "github";
      owner = "tqwewe";
      repo = "ashell";
      ref = "feat/peripherals";
    };

    # Helix
    helix = {
      url = "github:helix-editor/helix/25.01";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust devshell
    rust-devshell.url = "path:./devshells/rust";
    rust-devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Zellij statusbar
    zjstatus.url = "github:dj95/zjstatus";

    # Secrets & encryption
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
  };

  outputs =
    {
      nixpkgs,
      unstable,
      nix-darwin,
      home-manager,
      agenix,
      rust-devshell,
      ...
    }@inputs:
    let
      homeConfig =
        {
          module,
          system ? "x86_64-linux",
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            inherit inputs;
            inherit system;
          };
          modules = [ module ];
        };
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = function: nixpkgs.lib.genAttrs supportedSystems function;
    in
    {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./system/desktop/configuration.nix
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
        "ari@desktop" = homeConfig { module = ./home/desktop.nix; };
        "ari@Aris-MacBook-Pro" = homeConfig {
          module = ./home/macbook.nix;
          system = "x86_64-darwin";
        };
      };

      devShells = forAllSystems (system: {
        rust = rust-devshell.devShells.${system}.default;
      });
    };
}
