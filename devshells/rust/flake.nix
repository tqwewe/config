{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = function: nixpkgs.lib.genAttrs supportedSystems function;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };

          # Define the shell directly here, instead of importing
          rustToolchain = pkgs.rust-bin.stable.latest.default;

          devShell = pkgs.mkShell {
            name = "rust-dev";
            buildInputs =
              with pkgs;
              [
                bacon
                cargo-expand
                cargo-generate
                cargo-outdated
                cargo-temp
                rustToolchain
                pkg-config
                openssl.dev
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (
                with pkgs.darwin.apple_sdk.frameworks;
                [
                  CoreServices
                  CoreFoundation
                  Security
                  System
                  SystemConfiguration
                ]
              );
          };
        in
        {
          default = devShell;
        }
      );
    };
}
