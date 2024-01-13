{
  description = "Ari's NixOS config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # NUR
    nur.url = "github:nix-community/NUR";

    # Hardware quirks
    hardware.url = "github:nixos/nixos-hardware";

    # Rust oxalica overlay
    rust-overlay.url = "github:oxalica/rust-overlay";

    # Helix
    helix.url = "github:helix-editor/helix";
    # helix.url = "github:pascalkuthe/helix/inline-diagnostics";
    # helix.url = "github:tqwewe/helix-tree-explorer/tree_explore";
    helix.inputs.nixpkgs.follows = "nixpkgs";

    # Lunatic
    lunatic.url = "github:tqwewe/lunatic-flake";

    # Cocogitto
    cocogitto.url = "github:tqwewe/cocogitto-nix";

    # Bacon
    #bacon.url = "github:tqwewe/bacon-flake";

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

  outputs = { nixpkgs, home-manager, nur, ... }@inputs: {
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
    };

    devShells.x86_64-linux.default =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        packages = builtins.attrValues {
          inherit (pkgs) pkg-config openssl cmake fontconfig;
        };
      };
  };
}
