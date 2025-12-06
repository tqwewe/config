{
  description = "A friendly `quit` plugin for zellij";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    crane = {
      url = "github:ipetkov/crane";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    src = {
      url = "github:cristiand391/zj-quit";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      flake-utils,
      rust-overlay,
      src,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        rustWithWasiTarget = pkgs.rust-bin.stable."1.91.1".default.override {
          extensions = [
            "rust-src"
            "rust-std"
            "rust-analyzer"
          ];
          targets = [ "wasm32-wasip1" ];
        };

        # NB: we don't need to overlay our custom toolchain for the *entire*
        # pkgs (which would require rebuidling anything else which uses rust).
        # Instead, we just want to update the scope that crane will use by appending
        # our specific toolchain there.
        craneLib = (crane.mkLib pkgs).overrideToolchain rustWithWasiTarget;

        patchedSrc = pkgs.runCommand "patched-zj-quit" { } ''
          cp -r ${src} $out
          chmod -R +w $out
          sed -i 's/wasm32-wasi/wasm32-wasip1/' $out/.cargo/config.toml
        '';

        zj-quit = craneLib.buildPackage {
          src = patchedSrc;

          cargoExtraArgs = "--target wasm32-wasip1";

          # Tests currently need to be run via `cargo wasi` which
          # isn't packaged in nixpkgs yet...
          doCheck = false;
          doNotSign = true;

          buildInputs = [
            # Add additional build inputs here
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
          ];
        };
      in
      {
        checks = {
          inherit zj-quit;
        };

        packages.default = zj-quit;
      }
    );
}
