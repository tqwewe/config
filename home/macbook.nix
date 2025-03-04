{ inputs, pkgs, ... }:

let
  #cocogitto = inputs.cocogitto.packages.x86_64-darwin.default;
  # bacon = inputs.bacon.packages.x86_64-darwin.default;
  helix = inputs.helix.packages.x86_64-darwin.default;
  #lunatic-unstable = inputs.lunatic.packages.x86_64-darwin.unstable;
  unstable = inputs.unstable.legacyPackages.x86_64-darwin;

  # rust-overlay-wasi = (pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default)).override {
  #   extensions = [ "rust-src" "rustfmt" "rust-analyzer" ];
  #   targets = [ "wasm32-wasi" "wasm32-unknown-unknown" ];
  # };
  rust-overlay-wasi = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rustfmt" "rust-analyzer" ];
    targets = [ "wasm32-unknown-unknown" ];
  };
in
{
  imports = with inputs; [
    agenix.homeManagerModules.default
    ../system/modules/secrets.nix

    ./modules/alacritty.nix
    ./modules/base.nix
    ./modules/direnv.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/lazygit.nix
    ./modules/neovim.nix
    ./modules/starship.nix
    # ./modules/vscode.nix
    ./modules/zellij.nix
  ];

  nixpkgs = {
    overlays = with inputs; [
      (final: prev: {
        zjstatus = zjstatus.packages.${prev.system}.default;
      })
    ];
  };

  home = {
    username = "ari";
    homeDirectory = "/Users/ari";
    sessionVariables = {
      EDITOR = "hx";
    };
  };

  # User programs & packages
  programs.bat.enable = true;
  programs.bottom.enable = true;
  programs.eza.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    bacon
    unstable.cargo-expand
    unstable.cargo-generate
    unstable.cargo-outdated
    unstable.cargo-temp
    helix-gpt
    #cocogitto
    #docker-compose
    gcc
    # unstable.lapce
    nodejs
    nodePackages.vscode-langservers-extracted
    nodePackages.typescript-language-server
    ripgrep
    rust-overlay-wasi
    unstable.nodePackages.svelte-language-server
    tailwindcss-language-server
    vscode-langservers-extracted
    unstable.yazi

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
