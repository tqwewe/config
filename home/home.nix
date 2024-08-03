{ inputs, pkgs, ... }@foo:

let
  # atuin = inputs.atuin.packages.x86_64-linux.default;
  cocogitto = inputs.cocogitto.packages.x86_64-linux.default;
  bacon = inputs.bacon.packages.x86_64-linux.default;
  # cargo-leptos = inputs.cargo-leptos.packages.x86_64-linux.default;
  helix = inputs.helix.packages.x86_64-linux.default;
  lunatic-unstable = inputs.lunatic.packages.x86_64-linux.unstable;
  webcam = inputs.webcam.packages.x86_64-linux.default;
  unstable = inputs.unstable.legacyPackages.x86_64-linux;

  rust-overlay-wasi = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rustfmt" "rust-analyzer" ];
    targets = [ "wasm32-wasi" "wasm32-unknown-unknown" ];
  };
in
{
  imports = with inputs; [
    ./modules/alacritty.nix
    ./modules/base.nix
    ./modules/dconf.nix
    ./modules/direnv.nix
    ./modules/firefox.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/lazygit.nix
    ./modules/librewolf.nix
    ./modules/nur.nix
    ./modules/ssh.nix
    ./modules/starship.nix
    ./modules/thunderbird.nix
    ./modules/wezterm.nix
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
  programs.alacritty.enable = true;
  programs.bat.enable = true;
  programs.bottom.enable = true;
  programs.chromium.enable = true;
  programs.eza.enable = true;
  programs.obs-studio.enable = true;
  programs.obs-studio.plugins = [ pkgs.obs-studio-plugins.obs-backgroundremoval ];
  programs.rtorrent.enable = true;
  programs.vscode.enable = true;
  programs.wezterm.enable = true;
  programs.zoxide.enable = true;

  home.packages = with pkgs; [
    # atuin
    bacon
    unstable.cargo-expand
    unstable.cargo-generate
    # cargo-leptos
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
    # unstable.ollama
    libreoffice
    lunatic-unstable
    materia-kde-theme
    unstable.neovim
    netflix
    nodejs
    nodePackages.vscode-langservers-extracted
    nodePackages.typescript-language-server
    obsidian
    peek
    qbittorrent
    ripgrep
    rnote
    rust-overlay-wasi
    spotify
    sumneko-lua-language-server
    tdesktop
    viber
    vlc
    xclip
    webcam
    whatsapp-for-linux
    unstable.yazi
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
