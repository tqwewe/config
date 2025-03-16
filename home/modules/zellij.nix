{ inputs, lib, pkgs, ... }: let
  zjstatus_wasm = "file:${pkgs.zjstatus}/bin/zjstatus.wasm";
in {
  programs.zellij = {
    enable = true;
    package = inputs.unstable.legacyPackages.${pkgs.system}.zellij;

    enableFishIntegration = false;
    settings = {
      theme = "kanagawa";
    }; 
  };
  xdg.configFile."zellij/config.kdl".text = ''
    keybinds {
      unbind "Ctrl h" "Ctrl o" "Alt Left" "Alt Right" "Alt i" "Alt o"
      shared_except "move" "locked" {
        bind "Ctrl k" { SwitchToMode "Move"; }
      }
    }
  '';
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
      tab {
        pane
      }

      swap_tiled_layout name="vertical" {
            tab max_panes=5 {
            pane split_direction="vertical" {
                pane
                pane { children; }
            }
        }
        tab max_panes=8 {
            pane split_direction="vertical" {
                pane { children; }
                pane { pane; pane; pane; pane; }
            }
        }
        tab max_panes=12 {
            pane split_direction="vertical" {
                pane { children; }
                pane { pane; pane; pane; pane; }
                pane { pane; pane; pane; pane; }
            }
        }
      }

      swap_tiled_layout name="horizontal" {
            tab max_panes=5 {
            pane
            pane
        }
        tab max_panes=8 {
            pane {
                pane split_direction="vertical" { children; }
                pane split_direction="vertical" { pane; pane; pane; pane; }
            }
        }
        tab max_panes=12 {
            pane {
                pane split_direction="vertical" { children; }
                pane split_direction="vertical" { pane; pane; pane; pane; }
                pane split_direction="vertical" { pane; pane; pane; pane; }
            }
        }
      }

      default_tab_template {
        children
        pane size=1 borderless=true {
          plugin location="${zjstatus_wasm}" {
            format_left  "{mode}#[fg=black,bg=blue,bold]{session}  #[fg=blue,bg=#181825]{tabs}"
            format_right "#[fg=#181825,bg=#b1bbfa]{datetime}#[fg=#6C7086,bg=#b1bbfa,bold]{swap_layout} "
            format_space "#[bg=#181825]"

            hide_frame_for_single_pane "false"

            mode_normal  "#[bg=blue] "

            tab_normal              "#[fg=#181825,bg=#4C4C59] #[fg=#000000,bg=#4C4C59]{index}  {name} #[fg=#4C4C59,bg=#181825]"
            tab_normal_fullscreen   "#[fg=#6C7086,bg=#181825] {index} {name} [] "
            tab_normal_sync         "#[fg=#6C7086,bg=#181825] {index} {name} <> "
            tab_active              "#[fg=#181825,bg=#ffffff,bold,italic] {index}  {name} #[fg=#ffffff,bg=#181825]"
            tab_active_fullscreen   "#[fg=#9399B2,bg=#181825,bold,italic] {index} {name} [] "
            tab_active_sync         "#[fg=#9399B2,bg=#181825,bold,italic] {index} {name} <> "

            datetime          "#[fg=#6C7086,bg=#b1bbfa,bold] {format} "
            datetime_format   "%A, %d %b %Y %I:%M %P"
            datetime_timezone "Australia/Adelaide"
          }
        }
      }
    }
  '';
  programs.fish.interactiveShellInit = lib.mkOrder 205 ''
    eval (zellij setup --generate-completion fish | string collect)
  '';
}
