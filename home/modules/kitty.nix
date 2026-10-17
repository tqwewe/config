{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      name = "Hack Nerd Font Mono";
      package = pkgs.nerd-fonts.hack;
    };

    shellIntegration.enableFishIntegration = true;

    settings = {
      background_opacity = 0.98;
      enabled_layouts = "splits,stack";

      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      tab_bar_min_tabs = 2;
      tab_bar_margin_height = "4.0 0.0";
      tab_title_max_length = 28;
      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{index}: {title}";
      active_tab_title_template = "{index}: {title}";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";
      active_tab_foreground = "#212121";
      active_tab_background = "#53a4f3";
      inactive_tab_foreground = "#9e9e9e";
      inactive_tab_background = "#2e2e2d";
      tab_bar_background = "#1b1b1a";
    };

    keybindings = {
      "alt+n" = "launch --location=split --cwd=current";
      "alt+h" = "kitten focus.py left";
      "alt+j" = "neighboring_window down";
      "alt+k" = "neighboring_window up";
      "alt+l" = "kitten focus.py right";
      "alt+shift+h" = "previous_tab";
      "alt+shift+l" = "next_tab";
      "alt+f" = "toggle_layout stack";
      "ctrl+t>n" = "new_tab_with_cwd";
      "ctrl+t>x" = "close_tab";
      "ctrl+p>x" = "close_window";
      "ctrl+p>d" = "launch --location=hsplit --cwd=current";
      "ctrl+p>r" = "launch --location=vsplit --cwd=current";
    };

    # Sticky modes like zellij: ctrl+k moves panes, ctrl+n resizes them.
    extraConfig = ''
      map --new-mode move --on-unknown end ctrl+k
      map --mode move h move_window left
      map --mode move j move_window down
      map --mode move k move_window up
      map --mode move l move_window right
      map --mode move esc pop_keyboard_mode
      map --mode move enter pop_keyboard_mode

      map --new-mode resize --on-unknown end ctrl+n
      map --mode resize h kitten resize.py left 5
      map --mode resize l kitten resize.py right 5
      map --mode resize j kitten resize.py down 5
      map --mode resize k kitten resize.py up 5
      map --mode resize esc pop_keyboard_mode
      map --mode resize enter pop_keyboard_mode
    '';

    themeFile = "MaterialDark";
  };

  xdg.configFile."kitty/resize.py".source = ./kitty-resize.py;
  xdg.configFile."kitty/focus.py".source = ./kitty-focus.py;
}
