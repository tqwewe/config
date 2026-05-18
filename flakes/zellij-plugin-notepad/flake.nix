{
  description = "Zellij plugin for a floating vimput notepad with toggle behavior";

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
        owner = "0xble";
        repo = "zellij-notepad";
        version = "0.2.1";
        wasm = "notepad.wasm";

        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = repo;
          version = version;

          src = pkgs.fetchurl {
            url = "https://github.com/${owner}/${repo}/releases/download/v${version}/${wasm}";
            hash = "sha256-eyCBJwPwdrBo2f19Y94YpJvwzt70+H317lbqyKBT8og=";
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
