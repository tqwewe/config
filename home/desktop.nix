{
  inputs,
  pkgs,
  ...
}:
{
  imports = with inputs; [
    inputs.plasma-manager.homeModules.plasma-manager

    ./modules/base.nix
    ./modules/direnv.nix
    ./modules/docker.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/jujutsu.nix
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
  programs.btop.enable = true;
  programs.eza.enable = true;
  programs.zoxide.enable = true;

  home.packages =
    with pkgs;
    [
      ardour
      claude-code
      discord
      devenv
      git-cliff
      google-chrome
      guitarix
      killall
      libreoffice
      nautilus
      networkmanagerapplet
      nodejs
      obsidian
      proton-pass
      protonmail-desktop
      protonvpn-gui
      qbittorrent
      qjackctl
      reaper
      ripgrep
      signal-desktop
      spotify
      vlc
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
