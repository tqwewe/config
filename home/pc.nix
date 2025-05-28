{ inputs, pkgs, ... }@foo:

let
  helix = inputs.helix.packages.x86_64-linux.default;
  # webcam = inputs.webcam.packages.x86_64-linux.default;
  unstable = inputs.unstable.legacyPackages.x86_64-linux;
in
{
  imports = with inputs; [
    ./modules/alacritty.nix
    ./modules/base.nix
    ./modules/dconf.nix
    ./modules/direnv.nix
    # ./modules/firefox.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/hyprland.nix
    ./modules/kitty.nix
    ./modules/lazygit.nix
    ./modules/librewolf.nix
    ./modules/mangohud.nix
    ./modules/nur.nix
    ./modules/starship.nix
    ./modules/thunderbird.nix
    ./modules/wezterm.nix
    ./modules/zellij.nix
    hyprpanel.homeManagerModules.hyprpanel

    # Secrets
    agenix.homeManagerModules.default
    ../system/modules/secrets.nix
  ];

  nixpkgs = {
    overlays = with inputs; [
      (final: prev: {
        zjstatus = zjstatus.packages.${prev.system}.default;
      })
      hyprpanel.overlay
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
  programs.eza.enable = true;
  programs.obs-studio.enable = true;
  programs.obs-studio.plugins = [ pkgs.obs-studio-plugins.obs-backgroundremoval ];
  programs.rtorrent.enable = true;
  programs.vscode.enable = true;
  programs.wezterm.enable = true;
  programs.zoxide.enable = true;

  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "nautilus";
      };
    };
  };

  home.packages = with pkgs; [
    # atuin
    inputs.ashell.defaultPackage.${pkgs.system}
    discord
    docker-compose
    gcc
    # unstable.git-cliff
    # helix
    # insomnia
    killall
    unstable.kooha
    # unstable.ollama
    libreoffice
    # lunatic-unstable
    materia-kde-theme
    # unstable.neovim
    nautilus
    netflix
    networkmanagerapplet
    nodejs
    obsidian
    peek
    protonvpn-gui
    protonvpn-cli
    proton-pass
    qbittorrent
    ripgrep
    rnote
    spotify
    sumneko-lua-language-server
    tdesktop
    viber
    vlc
    # xclip
    # webcam
    whatsapp-for-linux
    unstable.yazi
    zoom-us

    # Fonts
    (pkgs.nerdfonts.override {
      fonts = [
        "FiraCode"
        "DroidSansMono"
        "Terminus"
        "Noto"
      ];
    })

    # Gnome Extensions
    # gnome-extension-manager
    # gnome-tweaks
    # gnomeExtensions.appindicator
    # gnomeExtensions.arcmenu
    # gnomeExtensions.blur-my-shell
    # gnomeExtensions.dash-to-panel
    # gnomeExtensions.desktop-icons-ng-ding
    # # gnomeExtensions.openweather
    # gnomeExtensions.tiling-assistant
    # gnomeExtensions.vitals
  ];
}
