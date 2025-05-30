{ inputs, pkgs, ... }:
{
  imports = with inputs; [
    ./modules/alacritty.nix
    ./modules/base.nix
    ./modules/direnv.nix
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
    ./modules/zellij.nix

    # Secrets
    agenix.homeManagerModules.default
    ../system/modules/secrets.nix
  ];

  home = {
    username = "ari";
    homeDirectory = "/home/ari";
  };

  # User programs & packages
  programs.bat.enable = true;
  programs.bottom.enable = true;
  programs.eza.enable = true;
  programs.obs-studio.enable = true;
  programs.obs-studio.plugins = [ pkgs.obs-studio-plugins.obs-backgroundremoval ];
  programs.zoxide.enable = true;

  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "nautilus";
        "application/x-directory" = "nautilus";
      };
    };
  };

  home.packages = with pkgs; [
    inputs.ashell.defaultPackage.${pkgs.system}
    discord
    docker-compose
    killall
    libreoffice
    nautilus
    networkmanagerapplet
    nodejs
    obsidian
    protonvpn-gui
    protonvpn-cli
    proton-pass
    qbittorrent
    ripgrep
    spotify
    vlc
    yazi

    # Fonts
    (pkgs.nerdfonts.override {
      fonts = [
        "FiraCode"
        "DroidSansMono"
        "Terminus"
        "Noto"
      ];
    })
  ];
}
