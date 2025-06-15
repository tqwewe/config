{
  description = "Rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = function: nixpkgs.lib.genAttrs supportedSystems function;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };
          
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" "rustfmt" "rust-analyzer" ];
            targets = [ "wasm32-wasip1" ];
          };
          
          devShell = pkgs.mkShell {
            name = "rust-dev";

            buildInputs = with pkgs; [
              bacon
              cargo-expand
              cargo-generate
              cargo-outdated
              cargo-temp
              rustToolchain
              pkg-config
              openssl.dev
              protobuf
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
              CoreServices
              CoreFoundation
              Security
              System
              SystemConfiguration
            ]);

            env = {
              PROTOC = "${pkgs.protobuf}/bin/protoc";
              PROTOC_INCLUDE = "${pkgs.protobuf}/include";
            };
          };
        in
        {
          default = devShell;
        }
      );
    };
}
