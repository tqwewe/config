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
          --append-flags "--disable-features=WaylandPerSurfaceScale,WaylandFractionalScaleV1"
      '';
    });
in
{
  imports = with inputs; [
    plasma-manager.homeModules.plasma-manager

    ./modules/atuin.nix
    ./modules/base.nix
    ./modules/devenv.nix
    ./modules/direnv.nix
    ./modules/docker.nix
    ./modules/fish.nix
    ./modules/gh.nix
    ./modules/git.nix
    ./modules/helix.nix
    # ./modules/herdr.nix
    ./modules/jujutsu.nix
    ./modules/kitty.nix
    ./modules/lazygit.nix
    ./modules/librewolf.nix
    ./modules/mangohud.nix
    ./modules/murmur.nix
    ./modules/nur.nix
    ./modules/obs.nix
    ./modules/ollama.nix
    # ./modules/openclaw.nix  # disabled: upstream removed programs.openclaw.documents
    ./modules/plasma.nix
    ./modules/starship.nix
    ./modules/taskwarrior.nix
    # ./modules/zellij.nix

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
    thunderbird.enable = true;
    zoxide.enable = true;
  };

  home.sessionVariables = {
    ELECTRON_EXTRA_LAUNCH_ARGS = "--disable-features=WaylandPerSurfaceScale,WaylandFractionalScaleV1";
  };

  services.protonmail-bridge.enable = true;

  systemd.user.services.protonmail-bridge = {
    Unit = {
      After = [
        "graphical-session.target"
        "network-online.target"
      ];
      Wants = [ "network-online.target" ];
      # rapid Restart=always restarts raced on the bridge lock file -> start-limit-hit
      StartLimitIntervalSec = 0;
    };
    Service = {
      # DNS lives entirely behind Tailscale MagicDNS, which isn't serving yet when
      # network-online.target is reached, so the bridge starts into a dead resolver.
      # Wait until the API host actually resolves before launching.
      ExecStartPre = pkgs.writeShellScript "wait-for-proton-dns" ''
        for i in $(seq 1 60); do
          ${pkgs.getent}/bin/getent ahosts mail-api.proton.me > /dev/null && exit 0
          sleep 1
        done
        exit 0
      '';
      RestartSec = 5;
    };
  };

  home.packages =
    with pkgs;
    [
      ardour
      bacon
      # Only build the Cycles CUDA kernel for this machine's GPU (RTX 4070 =
      # sm_89). nixpkgs otherwise builds cubins for every arch
      # (sm_75..sm_121), ~9x the ptxas work for no benefit here. Replace the
      # injected arch flag rather than appending, so there's exactly one.
      ((blender.override { cudaSupport = true; }).overrideAttrs (old: {
        cmakeFlags =
          builtins.filter (f: !lib.hasInfix "CYCLES_CUDA_BINARIES_ARCH" f) (old.cmakeFlags or [ ])
          ++ [ (lib.cmakeFeature "CYCLES_CUDA_BINARIES_ARCH" "sm_89") ];
      }))
      cinny-desktop
      claude-code
      # (withWaylandFix element-desktop)
      fd
      git-cliff
      (withWaylandFix google-chrome)
      # guitarix
      hubstaff
      killall
      libreoffice
      nautilus
      networkmanagerapplet
      (withWaylandFix obsidian)
      (withWaylandFix proton-pass)
      (withWaylandFix protonmail-desktop)
      proton-vpn
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
