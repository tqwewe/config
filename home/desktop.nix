{
  inputs,
  pkgs,
  ...
}:
let
  withWaylandFix =
    pkg:
    pkg.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/${pkg.meta.mainProgram or pkg.pname} \
          --append-flags "--disable-features=WaylandPerSurfaceScale"
      '';
    });
in
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
    ./modules/openclaw.nix
    ./modules/plasma.nix
    ./modules/starship.nix
    ./modules/taskwarrior.nix
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
  programs = {
    bat.enable = true;
    btop.enable = true;
    eza.enable = true;
    zoxide.enable = true;
  };

  home.sessionVariables = {
    ELECTRON_EXTRA_LAUNCH_ARGS = "--disable-features=WaylandPerSurfaceScale";
  };

  home.packages =
    with pkgs;
    [
      ardour
      bacon
      claude-code
      devenv
      element-desktop
      git-cliff
      (withWaylandFix google-chrome)
      # guitarix
      killall
      libreoffice
      nautilus
      networkmanagerapplet
      (withWaylandFix obsidian)
      (withWaylandFix proton-pass)
      (withWaylandFix protonmail-desktop)
      protonvpn-gui
      qbittorrent
      qjackctl
      reaper
      ripgrep
      sd # sed alternative
      signal-desktop
      (withWaylandFix spotify)
      inputs.steel.packages.${system}.default
      telegram-desktop
      vesktop
      vlc
      xxd
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
