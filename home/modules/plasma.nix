{ pkgs, ... }:
let
  beautifulTreeSplash = pkgs.callPackage ../../pkgs/beautiful-tree-animation-splash.nix { };
  watchDogsSplash = pkgs.callPackage ../../pkgs/watch-dogs-splash { };

  # Common widget configurations
  kickoffWidget = {
    name = "org.kde.plasma.kickoff";
    config = {
      General = {
        icon = "applications-all-symbolic";
        systemFavorites = "suspend,hibernate,reboot,shutdown";
        favoritesPortedToKAstats = true;
      };
    };
  };

  pagerWidget = {
    name = "org.kde.plasma.pager";
    config = {
      General = {
        showWindowIcons = true;
      };
    };
  };

  taskManagerWidget = {
    name = "org.kde.plasma.icontasks";
    config = {
      General = {
        indicateAudioStreams = false;
        launchers = [
          "preferred://browser"
          "preferred://filemanager"
          "applications:steam.desktop"
          "applications:discord.desktop"
          "applications:spotify.desktop"
          "applications:kitty.desktop"
        ];
      };
    };
  };

  spacerWidget = {
    name = "org.kde.plasma.panelspacer";
  };

  separatorWidget = {
    name = "org.kde.plasma.marginsseparator";
  };

  systemTrayWidget = {
    name = "org.kde.plasma.systemtray";
    config = {
      General = {
        extraItems = "org.kde.plasma.cameraindicator,org.kde.plasma.mediacontroller,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.volume,org.kde.plasma.keyboardlayout,org.kde.plasma.keyboardindicator,org.kde.plasma.brightness,org.kde.plasma.networkmanagement,org.kde.kscreen,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.weather,org.kde.kdeconnect,org.kde.plasma.notifications";
        hiddenItems = "org.kde.plasma.battery,org.kde.plasma.brightness";
        shownItems = "org.kde.plasma.notifications";
      };
    };
  };

  clockWidget = {
    digitalClock = {
      calendar = {
        firstDayOfWeek = "monday";
      };
      time = {
        format = "12h";
      };
    };
  };

  showDesktopWidget = {
    name = "org.kde.plasma.showdesktop";
  };

  # Common panel widgets (without initial spacer)
  commonWidgets = [
    kickoffWidget
    pagerWidget
    taskManagerWidget
    spacerWidget
    separatorWidget
    systemTrayWidget
    clockWidget
    showDesktopWidget
  ];

  # Panel with initial spacer (Screen 0)
  panelWithSpacer = [ spacerWidget ] ++ commonWidgets;

  # Common panel properties
  commonPanelProps = {
    location = "bottom";
    height = 44;
  };
in
{
  home.packages = with pkgs; [
    beautifulTreeSplash
    kora-icon-theme
    watchDogsSplash
  ];

  services.kdeconnect.enable = true;

  programs.plasma = {
    enable = true;

    configFile = {
      kwinrc.Xwayland.Scale = 1;

      "autostart/discord.desktop" = {
        "Desktop Entry" = {
          Categories = "Network;InstantMessaging";
          Exec = "Discord --start-minimized";
          "GenericName[en_AU]" = "All-in-one cross-platform voice and text chat for gamers";
          GenericName = "All-in-one cross-platform voice and text chat for gamers";
          Icon = "discord";
          "Name[en_AU]" = "Discord";
          Name = "Discord";
          StartupNotify = true;
          StartupWMClass = "discord";
          Terminal = false;
          Type = "Application";
          Version = "1.4";
          "X-KDE-SubstituteUID" = false;
        };
      };

      "autostart/steam.desktop" = {
        "Desktop Entry" = {
          Type = "Application";
          Name = "Steam";
          Comment = "Application for managing and playing games on Steam";
          Exec = "steam -silent %U";
          Icon = "steam";
          Categories = "Network;FileTransfer;Game";
          StartupNotify = true;
          Terminal = false;
          PrefersNonDefaultGPU = true;
          "X-KDE-RunOnDiscreteGpu" = true;
          "X-KDE-SubstituteUID" = false;
        };
      };
    };

    input = {
      mice = [
        {
          acceleration = 0.0;
          accelerationProfile = "none";
          enable = true;
          name = "Logitech G703 LS";
          productId = "4086";
          vendorId = "046d";
        }
      ];
    };

    panels = [
      # Panel for Screen 0 (Primary Monitor) - with initial spacer
      (
        commonPanelProps
        // {
          screen = 0;
          widgets = panelWithSpacer;
        }
      )

      # Panel for Screen 1 (Secondary Monitor) - no initial spacer
      (
        commonPanelProps
        // {
          screen = 1;
          widgets = commonWidgets;
        }
      )
    ];

    powerdevil = {
      AC = {
        powerProfile = "performance";
      };
    };

    workspace = {
      theme = "breeze-dark"; # Plasma theme
      colorScheme = "BreezeDark"; # Color scheme
      iconTheme = "kora"; # Icon theme
      cursor.theme = "breeze_cursors"; # Cursor theme

      wallpaper = "/run/current-system/sw/share/wallpapers/Next/";

      splashScreen = {
        theme = "watch-dogs-splash";
      };
    };
  };
}
