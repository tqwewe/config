{
  pkgs,
  inputs,
  ...
}:
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    xwayland.enable = true;
    plugins = [
      inputs.hyprland-plugins.packages."${pkgs.system}".hyprbars
      inputs.hyprland-plugins.packages."${pkgs.system}".hyprexpo
      inputs.hyprland-plugins.packages."${pkgs.system}".csgo-vulkan-fix
    ];
    systemd.enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun -show-icons";
      "$search" = "rofi -show window -show-icons";

      env = [
        "HYPRCURSOR_THEME,breezex-black"
        "HYPRCURSOR_SIZE,24"
      ];

      exec-once = [
        "copyq --start-server"
        "ashell"
      ];
      "$resize_on_border" = true;

      general = {
        border_size = 2;
        "col.active_border" = "0x4a73efff";
        gaps_out = "10,14,14,14";
        resize_on_border = true;

        snap = {
          enabled = true;
        };
      };

      decoration = {
        rounding = 8;
      };

      input = {
        follow_mouse = 2;
      };

      ecosystem = {
        no_donation_nag = true;
      };

      monitor = [
        "DP-1, 2560x1440@144, 0x0, 1"
      ];

      bind =
        [
          # shortcuts
          "$mod, T, exec, $terminal"
          "$mod, C, killactive,"
          "$mod, M, exit,"
          "$mod, E, exec, $fileManager"
          "$mod, F, fullscreen,"
          "$mod, G, togglefloating,"
          "$mod, R, exec, $menu"
          "$mod, P, pseudo,"

          # focus
          "$mod, h, movefocus, l"
          "$mod, j, movefocus, d"
          "$mod, k, movefocus, u"
          "$mod, l, movefocus, r"

          # resize
          "$mod SHIFT, h, resizeactive, -50 0"
          "$mod SHIFT, j, resizeactive, 0 50"
          "$mod SHIFT, k, resizeactive, 0 -50"
          "$mod SHIFT, l, resizeactive, 50 0"

          # resize
          "$mod ALT, h, movewindow, l"
          "$mod ALT, j, movewindow, d"
          "$mod ALT, k, movewindow, u"
          "$mod ALT, l, movewindow, r"

          # scroll workspace
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # special workspace
          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"

          # overview
          "$mod, grave, hyprexpo:expo, toggle"

          # screenshots
          "$mod, p, exec, hyprshot -m region"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (
            builtins.genList (
              i:
              let
                ws = i + 1;
              in
              [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            ) 9
          )
        );

      # hold binds
      bindo = [ ];

      # mouse binds
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      plugin = {
        hyprbars = {
          bar_color = "rgb(161616)";
          bar_height = 24;
          bar_button_padding = 8;
          hyprbars-button = [
            "rgb(ff4040), 12, 󰖭, hyprctl dispatch killactive"
            "rgb(eeee11), 12, , hyprctl dispatch fullscreen 1"
          ];
        };
      };
    };
  };

  services.copyq.enable = true;

  home.packages = with pkgs; [
    hyprshot
  ];

  programs.rofi = {
    enable = true;
    theme = "nordic";
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      preload = [ "~/dev/tqwewe/config/backgrounds/astro.jpg" ];
      wallpaper = [ ", ~/dev/tqwewe/config/backgrounds/astro.jpg" ];
    };
  };

  home.file.".config/ashell/config.toml".text = ''
    app_launcher_cmd = "rofi -show drun -show-icons"
    position = "Bottom"

    [modules]
    left = ["AppLauncher", "Workspaces"]
    center = ["MediaPlayer"]
    right = ["SystemInfo", "Tray", ["Clock", "Privacy", "Settings"]]

    [system]
    indicators = ["Cpu", "Memory", "Temperature", "Peripherals"]

    [clock]
    format = "%a, %d %b %l:%M %P"

    [settings]
    lock_cmd = "hyprlock &"

    [appearance]
    style = "Solid"
  '';

  home.file.".config/rofi/themes/nordic.rasi".text = ''
    * {
        bg0:    #2E3440F2;
        bg1:    #3B4252;
        bg2:    #4C566A80;
        bg3:    #88C0D0F2;
        fg0:    #D8DEE9;
        fg1:    #ECEFF4;
        fg2:    #D8DEE9;
        fg3:    #4C566A;
    }

    /* ROUNDED THEME FOR ROFI */
    /* Author: Newman Sanchez (https://github.com/newmanls) */

    * {
        font:   "Roboto 12";

        background-color:   transparent;
        text-color:         @fg0;

        margin:     0px;
        padding:    0px;
        spacing:    0px;
    }

    window {
        location:       north;
        y-offset:       calc(50% - 176px);
        width:          480;
        border-radius:  24px;

        background-color:   @bg0;
    }

    mainbox {
        padding:    12px;
    }

    inputbar {
        background-color:   @bg1;
        border-color:       @bg3;

        border:         2px;
        border-radius:  16px;

        padding:    8px 16px;
        spacing:    8px;
        children:   [ prompt, entry ];
    }

    prompt {
        text-color: @fg2;
    }

    entry {
        placeholder:        "Search";
        placeholder-color:  @fg3;
    }

    message {
        margin:             12px 0 0;
        border-radius:      16px;
        border-color:       @bg2;
        background-color:   @bg2;
    }

    textbox {
        padding:    8px 24px;
    }

    listview {
        background-color:   transparent;

        margin:     12px 0 0;
        lines:      8;
        columns:    1;

        fixed-height: false;
    }

    element {
        padding:        8px 16px;
        spacing:        8px;
        border-radius:  16px;
    }

    element normal active {
        text-color: @bg3;
    }

    element alternate active {
        text-color: @bg3;
    }

    element selected normal, element selected active {
        background-color:   @bg3;
    }

    element-icon {
        size:           1em;
        vertical-align: 0.5;
    }

    element-text {
        text-color: inherit;
    }
    element selected {
        text-color: @bg1;
    }
  '';

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 150; # 2.5 mins
          on-timeout = "~/.config/hypridle/scripts/brightness.sh save-and-dim";
          on-resume = "~/.config/hypridle/scripts/brightness.sh restore";
        }
        # {
        #   timeout = 300; # 5 mins
        #   on-timeout = "loginctl lock-session";
        # }
        # {
        #   timeout = 330; # 5.5 mins
        #   on-timeout = "hyprctl dispatch dpms off";
        #   on-resume = "hyprctl dispatch dpms on && sleep 1 && ~/.config/hypridle/scripts/brightness.sh restore && sleep 0.5 && hyprctl dispatch focuswindow hyprlock";
        # }
        # {
        #   # timeout = 1800; # 30 mins
        #   timeout = 40;
        #   on-timeout = "systemctl hybrid-sleep";
        # }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        grace = 300;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "~/dev/tqwewe/config/backgrounds/astro.jpg";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      # input-field = [
      #   {
      #     size = "200, 50";
      #     position = "0, -80";
      #     monitor = "";
      #     dots_center = true;
      #     fade_on_empty = false;
      #     font_color = "rgb(202, 211, 245)";
      #     inner_color = "rgb(91, 96, 120)";
      #     outer_color = "rgb(24, 25, 38)";
      #     outline_thickness = 5;
      #     placeholder_text = "Password...";
      #     shadow_passes = 2;
      #   }
      # ];
    };
  };

  home.file.".local/share/icons/breezex-black" = {
    source = ./breezex-black;
    recursive = true;
  };

  home.file.".config/hypridle/scripts/brightness.sh" = {
    text = ''
      #!/usr/bin/env bash

      BRIGHTNESS_FILE="/tmp/hypridle_brightness"
      DEFAULT_BRIGHTNESS=80
      DIM_BRIGHTNESS=10

      save_brightness() {
          local current
          current=$(ddcutil getvcp 10 2>/dev/null | grep -o 'current value =[ ]*[0-9]*' | grep -o '[0-9]*')
          if [ -n "$current" ] && [ "$current" -gt 0 ]; then
              echo "$current" > "$BRIGHTNESS_FILE"
              echo "Saved brightness: $current"
          else
              echo "Failed to get current brightness, using default"
              echo "$DEFAULT_BRIGHTNESS" > "$BRIGHTNESS_FILE"
          fi
      }

      restore_brightness() {
          local saved="$DEFAULT_BRIGHTNESS"
          if [ -f "$BRIGHTNESS_FILE" ]; then
              saved=$(cat "$BRIGHTNESS_FILE")
          fi
          
          if [ -n "$saved" ] && [ "$saved" -gt 0 ]; then
              ddcutil setvcp 10 "$saved"
              echo "Restored brightness: $saved"
          else
              ddcutil setvcp 10 "$DEFAULT_BRIGHTNESS"
              echo "Used default brightness: $DEFAULT_BRIGHTNESS"
          fi
      }

      case "$1" in
          save-and-dim)
              save_brightness
              ddcutil setvcp 10 "$DIM_BRIGHTNESS"
              ;;
          restore)
              restore_brightness
              ;;
          *)
              echo "Usage: $0 {save-and-dim|restore}"
              exit 1
              ;;
      esac
    '';
    executable = true; # This makes the file executable
  };
}
