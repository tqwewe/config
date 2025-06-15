{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  home = {
    packages =
      with inputs.unstable.legacyPackages.${pkgs.system};
      [
        gnome-extension-manager
        gnome-tweaks
      ]
      ++ (with gnomeExtensions; [
        appindicator
        arcmenu
        blur-my-shell
        dash-to-panel
        desktop-icons-ng-ding
        gsconnect
        vitals
      ]);

    activation.profilePicture = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${pkgs.curl}/bin/curl -L -o $HOME/.face "https://avatars.githubusercontent.com/u/16362377?v=4"
    '';
  };

  gtk = {
    enable = true;

    theme = {
      name = "Orchis-Dark";
      package = pkgs.orchis-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-options = "zoom";
      picture-uri = "file:///home/ari/dev/tqwewe/config/backgrounds/astro.jpg";
      picture-uri-dark = "file:///home/ari/dev/tqwewe/config/backgrounds/astro.jpg";
    };

    "org/gnome/desktop/interface" = {
      clock-format = "12h";
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-enable = true;
      night-light-schedule-automatic = true;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "interactive";
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      disabled-extensions = [
        "light-style@gnome-shell-extensions.gcampax.github.com"
        "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        "status-icons@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "window-list@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
      ];
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "arcmenu@arcmenu.com"
        "blur-my-shell@aunetx"
        "dash-to-panel@jderose9.github.com"
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "gsconnect@andyholmes.github.io"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "Vitals@CoreCoding.com"
      ];
      favorite-apps = [
        "librewolf.desktop"
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
        "discord.desktop"
        "kitty.desktop"
      ];
      last-selected-power-profile = "performance";
    };

    "org/gnome/shell/extensions/arcmenu" = {
      arc-menu-icon = 71;
      button-padding = -1;
      dash-to-panel-standalone = false;
      menu-button-appearance = "Icon";
      menu-button-border-radius = lib.hm.gvariant.mkTuple [
        true
        4
      ];
      menu-button-border-width = lib.hm.gvariant.mkTuple [
        false
        4
      ];
      menu-button-fg-color = lib.hm.gvariant.mkTuple [
        false
        "rgb(242,242,242)"
      ];
      menu-button-icon = "Menu_Icon";
      menu-layout = "Eleven";
      multi-monitor = false;
      override-menu-theme = false;
      pinned-apps = [
        (lib.hm.gvariant.mkDictionaryEntry [
          "id"
          "librewolf.desktop"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "id"
          "org.gnome.Nautilus.desktop"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "id"
          "kitty.desktop"
        ])
        (lib.hm.gvariant.mkDictionaryEntry [
          "id"
          "discord.desktop"
        ])
      ];
      position-in-panel = "Left";
      prefs-visible-page = 0;
      search-entry-border-radius = lib.hm.gvariant.mkTuple [
        true
        25
      ];
      show-activities-button = false;
      update-notifier-project-version = 65;
    };

    "org/gnome/shell/extensions/dash-to-panel" = {
      appicon-margin = 4;
      appicon-padding = 8;
      appicon-style = "NORMAL";
      dot-position = "BOTTOM";
      dot-style-focused = "METRO";
      dot-style-unfocused = "DASHES";
      global-border-radius = 0;
      group-apps = true;
      hide-overview-on-startup = true;
      panel-anchors = ''{"GBT-22012B001330":"MIDDLE"}'';
      panel-element-positions = ''{"GBT-22012B001330":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"centerMonitor"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'';
      panel-lengths = ''{"GBT-22012B001330":100}'';
      panel-positions = ''{"GBT-22012B001330":"BOTTOM"}'';
      panel-side-margins = 0;
      panel-side-padding = 0;
      panel-sizes = "{}";
      panel-top-bottom-margins = 0;
      panel-top-bottom-padding = 0;
      prefs-opened = false;
      primary-monitor = "GBT-22012B001330";
      progress-show-count = true;
      show-apps-icon-file = "";
      show-favorites = true;
      show-favorites-all-monitors = true;
      stockgs-keep-dash = false;
      stockgs-keep-top-panel = false;
      stockgs-panelbtn-click-only = false;
      trans-bg-color = "#000000";
      trans-panel-opacity = 0.40000000000000002;
      trans-use-custom-bg = false;
      trans-use-custom-gradient = false;
      trans-use-custom-opacity = false;
      trans-use-dynamic-opacity = false;
      window-preview-title-position = "TOP";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };
  };
}
