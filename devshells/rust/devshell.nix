{ pkgs, system ? builtins.currentSystem }:

let
  rustToolchain = pkgs.rust-bin.stable.latest.default;
in

pkgs.mkShell {
  name = "rust-dev";
  buildInputs = with pkgs; [
    bacon
    cargo-expand
    cargo-generate
    cargo-outdated
    cargo-temp
    clippy
    rustToolchain
    rust-analyzer
    pkg-config
    openssl.dev
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
    CoreServices
    CoreFoundation
    Security
    System
    SystemConfiguration
  ]);
  
  shellHook = ''
    echo -e "\n\033[38;5;208m🦀 Rust never sleeps, but it doesn't have memory leaks either!\033[0m"
    echo -e "\033[38;5;208m🦀 Ready to build something safe and concurrent!\033[0m\n"
  '';
}
