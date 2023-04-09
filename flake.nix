
{
  description = "Ari's NixOS config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware quirks
    hardware.url = "github:nixos/nixos-hardware";

    # Rust oxalica overlay
    rust-overlay.url = "github:oxalica/rust-overlay";

    # Lunatic
    lunatic.url = "github:tqwewe/lunatic-flake";

    # Cocogitto
    cocogitto.url = "github:tqwewe/cocogitto-nix";

    # Bacon
    bacon.url = "github:tqwewe/bacon-flake";

    mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-22.11";

    vscode-server.url = "github:msteen/nixos-vscode-server";

    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, vscode-server, ... }@inputs: {
    nixosConfigurations = {
      ari = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./system/desktop/configuration.nix
          vscode-server.nixosModule
          ({ config, pkgs, ... }: {
            services.vscode-server.enable = true;
          })
        ];
      };

      server = nixpkgs.lib.nixosSystem {
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
        modules = [ ./home/home.nix ];
      };

      "ari@server" = home-manager.lib.homeManagerConfiguration {
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
          inherit (pkgs) pkg-config openssl;
        };
      };
  };
}
