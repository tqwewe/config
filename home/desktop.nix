{
  inputs,
  pkgs,
  ...
}:
{
  imports = with inputs; [
    inputs.plasma-manager.homeManagerModules.plasma-manager

    ./modules/base.nix
    ./modules/direnv.nix
    ./modules/docker.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    # ./modules/gnome.nix
    ./modules/helix.nix
    ./modules/kitty.nix
    ./modules/lazygit.nix
    ./modules/librewolf.nix
    ./modules/mangohud.nix
    ./modules/nur.nix
    ./modules/obs.nix
    ./modules/ollama.nix
    ./modules/plasma.nix
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
  programs.zoxide.enable = true;

  home.packages =
    with pkgs;
    [
      discord
      git-cliff
      killall
      libreoffice
      nautilus
      networkmanagerapplet
      nodejs
      obsidian
      proton-pass
      protonmail-desktop
      protonvpn-cli
      protonvpn-gui
      qbittorrent
      ripgrep
      signal-desktop
      spotify
      vlc
      whatsie
      yazi
      zoom-us
    ]
    ++ (with nerd-fonts; [
      # Fonts
      droid-sans-mono
      fira-code
      hack
      noto
    ]);
}
