
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

    nvchad = {
      url = "github:cfcosta/nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-22.11";
  };

  outputs = { nixpkgs, home-manager, hardware, nvchad, mailserver, ... }@inputs: {
    nixosConfigurations = {
      ari = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./system/desktop/configuration.nix
        ];
      };

      server = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./system/server/configuration.nix
          ./modules/mailserver.nix
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
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
  };
}
