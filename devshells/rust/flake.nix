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

          rustToolchain = pkgs.rust-bin.stable."1.91.1".default.override {
            extensions = [
              "rust-src"
              "rustfmt"
              "rust-analyzer"
            ];
            targets = [ "wasm32-unknown-unknown" ];
          };

          devShell = pkgs.mkShell {
            name = "rust-dev";
            buildInputs = with pkgs; [
              bacon
              cargo-expand
              cargo-generate
              cargo-msrv
              cargo-outdated
              # cargo-semver-checks
              cargo-temp
              rustToolchain
              pkg-config
              openssl.dev
            ];
          };
        in
        {
          default = devShell;
        }
      );
    };
}
