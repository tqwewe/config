{ inputs, pkgs, ... }@foo:

let
  cocogitto = inputs.cocogitto.packages.x86_64-linux.default;
  bacon = inputs.bacon.packages.x86_64-linux.default;
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
    ./modules/dconf.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/lazygit.nix
    ./modules/librewolf.nix
    ./modules/ssh.nix
    ./modules/thunderbird.nix
    ./modules/tmux.nix
    ./modules/wezterm.nix
  ];

  # nixpkgs = {
  #   overlays = with inputs; [
  #     rust-overlay.overlays.default
  #   ];
  # };

  home = {
    username = "ari";
    homeDirectory = "/home/ari";
  };

  # User programs & packages
  programs.alacritty.enable = true;
  programs.bat.enable = true;
  programs.bottom.enable = true;
  programs.chromium.enable = true;
  programs.exa.enable = true;
  programs.obs-studio.enable = true;
  programs.obs-studio.plugins = [ pkgs.obs-studio-plugins.obs-backgroundremoval ];
  programs.rtorrent.enable = true;
  programs.starship.enable = true;
  programs.vscode.enable = true;
  programs.wezterm.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    bacon
    unstable.cargo-outdated
    cocogitto
    discord
    docker-compose
    gcc
    # unstable.git-cliff
    # helix
    insomnia
    killall
    unstable.kooha
    lunatic-unstable
    materia-kde-theme
    unstable.neovim
    netflix
    nodejs
    nodePackages.vscode-langservers-extracted
    obsidian
    peek
    qbittorrent
    ripgrep
    rnote
    rust-overlay-wasi
    spotify
    sumneko-lua-language-server
    tdesktop
    vlc
    xclip
    zoom-us

    # Fonts
    (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })

    # Gnome Extensions
    gnome-extension-manager
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
    gnomeExtensions.arcmenu
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-panel
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.openweather
    gnomeExtensions.tiling-assistant
    gnomeExtensions.vitals
  ];
}
