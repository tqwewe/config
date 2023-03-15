{ inputs, pkgs, ... }@foo:

let
  cocogitto = inputs.cocogitto.packages.x86_64-linux.default;
  lunatic-unstable = inputs.lunatic.packages.x86_64-linux.unstable;

  rust-overlay-wasi = pkgs.rust-bin.stable."1.66.1".default.override {
    extensions = [ "rust-src" "rustfmt" "rust-analyzer" ];
    targets = [ "wasm32-wasi" ];
  };
in
{
  # You can import other home-manager modules here
  imports = with inputs; [
    inputs.nvchad.hmModule

    # You can also split up your configuration and import pieces of it here:
    ./modules/base.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/librewolf.nix
    # ./modules/neovim.nix
    ./modules/ssh.nix
    ./modules/thunderbird.nix
  ];

  nixpkgs = {
    overlays = with inputs; [
      rust-overlay.overlays.default
    ];
  };

  programs.devos.neovim = {
    enable = true;
  };

  home = {
    username = "ari";
    homeDirectory = "/home/ari";
  };

  # User programs & packages
  programs.alacritty.enable = true;
  programs.bat.enable = true;
  programs.bottom.enable = true;
  programs.exa.enable = true;
  programs.obs-studio.enable = true;
  programs.rtorrent.enable = true;
  programs.starship.enable = true;
  programs.vscode.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    cocogitto
    discord
    gcc
    lunatic-unstable
    materia-kde-theme
    nodejs
    qbittorrent
    ripgrep
    rnote
    rust-overlay-wasi
    spotify
    tdesktop
    vlc

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
