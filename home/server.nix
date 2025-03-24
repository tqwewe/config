{ inputs, pkgs, ... }@foo:

let
  cocogitto = inputs.cocogitto.packages.x86_64-linux.default;
  #bacon = inputs.bacon.packages.x86_64-linux.default;
  helix = inputs.helix.packages.x86_64-linux.default;
  lunatic-unstable = inputs.lunatic.packages.x86_64-linux.unstable;
  unstable = inputs.unstable.legacyPackages.x86_64-linux;

  rust-overlay-wasi = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rustfmt" "rust-analyzer" ];
    targets = [ "wasm32-wasi" "wasm32-unknown-unknown" ];
  };
in
{
  imports = with inputs; [
    ./modules/base.nix
    ./modules/direnv.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    #./modules/helix.nix
    ./modules/lazygit.nix
    ./modules/starship.nix
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
    homeDirectory = "/home/ari";
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
    cocogitto
    docker-compose
    gcc
    killall
    nodejs
    nodePackages.vscode-langservers-extracted
    nodePackages.typescript-language-server
    ripgrep
    rust-overlay-wasi
    unstable.yazi

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
