{
  description = "Ari's NixOS config";

  inputs = {
    # Nixpkgs
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      # url = "github:nix-community/home-manager/release-25.05";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirks
    hardware.url = "github:nixos/nixos-hardware";

    # niri.url = "github:sodiboo/niri-flake";

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # hyprland.url = "github:hyprwm/Hyprland";
    # hyprland-plugins = {
    #   url = "github:hyprwm/hyprland-plugins";
    #   inputs.hyprland.follows = "hyprland";
    # };
    # hyprlock.url = "github:hyprwm/hyprlock";
    # # ashell.url = "github:MalpenZibo/ashell";
    # ashell = {
    #   type = "github";
    #   owner = "tqwewe";
    #   repo = "ashell";
    #   ref = "feat/peripherals";
    # };

    # Helix
    helix = {
      url = "github:mattwparas/helix/steel-event-system";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    steel = {
      url = "github:mattwparas/steel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-openclaw.url = "github:openclaw/nix-openclaw";
    hermes-agent.url = "github:NousResearch/hermes-agent";

    moonbit-overlay = {
      url = "github:moonbit-community/moonbit-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tree-sitter-moonbit = {
      url = "github:moonbitlang/tree-sitter-moonbit";
      flake = false;
    };

    # Rust devshell
    rust-devshell = {
      url = "path:./devshells/rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zellij status bar
    zjstatus = {
      url = "github:dj95/zjstatus";
    };

    # Zellij quit prompt
    zj-quit = {
      url = "path:./flakes/zj-quit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zellij session manager
    zellij-plugin-zsm = {
      url = "path:./flakes/zellij-plugin-zsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets & encryption
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs =
    {
      nixpkgs,
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
          modules = [
            module
          ];
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
            agenix.nixosModules.default
          ];
        };
        bigscreen = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./system/bigscreen/configuration.nix
          ];
        };
      };

      darwinConfigurations."Aris-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          ./system/macbook/configuration.nix
          agenix.darwinModules.default
        ];
      };

      homeConfigurations = {
        "ari@desktop" = homeConfig { module = ./home/desktop.nix; };
        "ari@bigscreen" = homeConfig { module = ./home/bigscreen.nix; };
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
