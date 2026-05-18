{
  description = "Zoxide Session Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        owner = "liam-mackie";
        repo = "zsm";
        version = "0.4.1";
        wasm = "${repo}.wasm";

        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = repo;
          version = version;

          src = pkgs.fetchurl {
            url = "https://github.com/${owner}/${repo}/releases/download/v${version}/${wasm}";
            hash = "sha256-+VCf9MEHQVmr2q8lu95jAOsvCQU0iJa3ljqbnIC9ywg=";
          };

          dontUnpack = true;

          installPhase = ''
            mkdir -p $out
            cp $src $out/plugin.wasm
          '';
        };
      }
    );
}
