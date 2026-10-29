{ inputs, lib, pkgs, ... }:
{
  imports = [
    inputs.plasma-manager.homeModules.plasma-manager

    ./modules/base.nix
    ./modules/devenv.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/helix.nix
    ./modules/kitty.nix
    ./modules/lazygit.nix
    ./modules/nh.nix
    ./modules/openclaw-bigscreen.nix
    ./modules/starship.nix
    ./modules/jellyfin-desktop.nix
    ./modules/mpv.nix
    ./modules/zellij.nix

    # Secrets
    inputs.agenix.homeManagerModules.default
    ../system/modules/secrets.nix
  ];

  home = {
    username = "ari";
    homeDirectory = "/home/ari";
  };

  programs = {
    bat.enable = true;
    btop.enable = true;
    eza.enable = true;
    zoxide.enable = true;
    # Readable from the couch
    kitty.font.size = 24;
  };

  # Launch Steam straight into Big Picture. Steam itself comes from the shared system
  # module, so override just its launcher here (the home profile wins over the system one).
  xdg.desktopEntries.steam = {
    name = "Steam";
    exec = "steam -gamepadui %U";
    icon = "steam";
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
  };

  home.packages = with pkgs; [
    claude-code
    discord
    firefox
    maliit-keyboard
    netflix
    playerctl
    proton-vpn
    ripgrep
    (spotify.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/spotify --add-flags "--force-device-scale-factor=1.5"
      '';
    }))
    spotify-player
    vacuum-tube
    vlc
  ];

  programs.plasma = {
    enable = true;
    workspace = {
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      cursor.theme = "breeze_cursors";
    };
    configFile."kwalletrc"."Wallet".Enabled = false;
    configFile."kscreenlockerrc"."Daemon".Autolock = false;
    configFile."kscreenlockerrc"."Daemon".LockOnResume = false;
    configFile."kwinrc"."Wayland"."InputMethod[$e]" = "${pkgs.maliit-keyboard}/share/applications/com.github.maliit.keyboard.desktop";
  };

  # Fix taskbar and quicklaunch widget icons: KDE stores absolute Nix store paths
  # when apps are pinned via the GUI, which break on every rebuild. Use kwriteconfig6
  # to keep stable application IDs in place after each activation.
  home.activation.fixPlasmaLaunchers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kwrite="${pkgs.kdePackages.kconfig}/bin/kwriteconfig6"
    cfg="plasma-org.kde.plasma.desktop-appletsrc"
    # Taskbar (icontasks)
    run "$kwrite" --file "$cfg" \
      --group Containments --group 2 --group Applets --group 5 --group Configuration --group General \
      --key launchers "preferred://browser,preferred://filemanager,applications:jellyfin-desktop.desktop,applications:steam.desktop,applications:kitty.desktop,applications:spotify.desktop"
    # Desktop quick launch widget — quicklaunch doesn't support applications: scheme,
    # so use file:// paths pointing to stable profile symlinks (no store hash)
    run "$kwrite" --file "$cfg" \
      --group Containments --group 1 --group Applets --group 29 --group Configuration --group General \
      --key launcherUrls "file://$HOME/.nix-profile/share/applications/firefox.desktop,file://$HOME/.nix-profile/share/applications/jellyfin-desktop.desktop,file:///run/current-system/sw/share/applications/org.kde.dolphin.desktop,file://$HOME/.nix-profile/share/applications/spotify.desktop,file://$HOME/.nix-profile/share/applications/netflix-via-google-chrome.desktop,file:///run/current-system/sw/share/applications/steam.desktop"
  '';
}
