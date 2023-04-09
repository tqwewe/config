{ inputs, pkgs, ... }@foo:

let
  cocogitto = inputs.cocogitto.packages.x86_64-linux.default;
  bacon = inputs.bacon.packages.x86_64-linux.default;
  lunatic-unstable = inputs.lunatic.packages.x86_64-linux.unstable;
  unstable = inputs.unstable.legacyPackages.x86_64-linux;

  rust-overlay-wasi = pkgs.rust-bin.stable."1.66.1".default.override {
    extensions = [ "rust-src" "rustfmt" "rust-analyzer" ];
    targets = [ "wasm32-wasi" ];
  };
in
{
  imports = with inputs; [
    ./modules/base.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/lazygit.nix
    ./modules/librewolf.nix
    ./modules/ssh.nix
    ./modules/thunderbird.nix
    ./modules/wezterm.nix
  ];

  nixpkgs = {
    overlays = with inputs; [
      rust-overlay.overlays.default
    ];
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
  programs.wezterm.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    bacon
    cargo-outdated
    cocogitto
    discord
    gcc
    unstable.git-cliff
    lunatic-unstable
    materia-kde-theme
    unstable.neovim
    nodejs
    qbittorrent
    ripgrep
    rnote
    rust-overlay-wasi
    spotify
    sumneko-lua-language-server
    tdesktop
    vlc
    xclip

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
}
