{
  description = "Ari's NixOS config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NUR
    nur.url = "github:nix-community/NUR";

    # Hardware quirks
    hardware.url = "github:nixos/nixos-hardware";

    # Rust oxalica overlay
    rust-overlay.url = "github:oxalica/rust-overlay";

    # Helix
    helix.url = "github:helix-editor/helix/2cadec0b1182332338a5a1cc3062776f834d8835";
    # helix.url = "github:pascalkuthe/helix/inline-diagnostics";
    # helix.url = "github:tqwewe/helix-tree-explorer/tree_explore";
    helix.inputs.nixpkgs.follows = "nixpkgs";

    # Lunatic
    lunatic.url = "github:tqwewe/lunatic-flake";

    # Cocogitto
    cocogitto.url = "github:tqwewe/cocogitto-nix";

    # Bacon
    bacon.url = "github:tqwewe/bacon-flake";

    # # Atuin
    # atuin.url = "github:atuinsh/atuin";

    # Cargo Leptos
    # cargo-leptos.url = "github:leptos-rs/cargo-leptos";

    # Virtual Webcam
    webcam.url = "github:tqwewe/usb-webcam-v4l2-ffmpeg-nix";

    # mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-22.11";

    # vscode-server.url = "github:msteen/nixos-vscode-server";
    zjstatus.url = "github:dj95/zjstatus";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, unstable, nixpkgs-darwin, nix-darwin, home-manager, nur, ... }@inputs: {
    nixosConfigurations = {
      ari = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          nur.nixosModules.nur
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
        home-manager.darwinModules.home-manager
        ./system/macbook/configuration.nix
      ];
    };

    homeConfigurations = {
      "ari@ari" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ nur.nixosModules.nur ./home/home.nix ];
      };

      "ari@cloud-dev" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/server.nix ];
      };

      "ari@Aris-MacBook-Pro" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs-darwin.legacyPackages.x86_64-darwin;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./home/macbook.nix ];
      };
    };

    overlays = {
      # Overlay useful on Macs with Apple Silicon
        apple-silicon = final: prev: unstable.lib.optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
          # Add access to x86 packages system is running Apple Silicon
          pkgs-x86 = import inputs.nixpkgs-unstable {
            system = "x86_64-darwin";
            # inherit (nixpkgsConfig) config;
          };
        }; 
      };

    devShells.x86_64-linux.default =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        packages = builtins.attrValues {
          inherit (pkgs) pkg-config openssl cmake fontconfig;
        };
      };
    # devShells.x86_64-darwin.default =
    #   let
    #     pkgs = nixpkgs.legacyPackages.x86_64-darwin;
    #   in pkgs.mkShell {
    #     packages = builtins.attrValues {
    #       inherit (pkgs) pkg-config openssl cmake fontconfig;
    #       buildInputs = [ pkgs.darwin.apple_sdk.frameworks.SystemConfiguration ];
    #     };
    #   };
  };
}
