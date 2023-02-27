# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, lib, config, pkgs, ... }:

let
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
    # You can add overlays here
    overlays = with inputs; [
      rust-overlay.overlays.default
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
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
  programs.exa.enable = true;
  programs.obs-studio.enable = true;
  programs.starship.enable = true;
  programs.vscode.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    discord
    gcc
    lunatic-unstable
    materia-kde-theme
    nodejs
    ripgrep
    rnote
    rust-overlay-wasi
    spotify
    tdesktop
    vlc

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  fonts.fontconfig.enable = true;

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
