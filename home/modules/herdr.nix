{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [ inputs.herdr.packages.${pkgs.system}.default ];

  # Shipped with the flake so the skill always matches the installed CLI.
  home.file.".claude/skills/herdr/SKILL.md".source = "${inputs.herdr}/skills/herdr/SKILL.md";

  # Mirrors the zellij keybindings. Herdr has no sticky modes, so the zellij mode
  # keys are extra prefixes: ctrl+k h/j/k/l swaps, ctrl+p x closes, ctrl+t n opens a tab.
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [keys]
    prefix = ["ctrl+b", "ctrl+k", "ctrl+p", "ctrl+t"]

    focus_pane_left = "alt+h"
    focus_pane_down = "alt+j"
    focus_pane_up = "alt+k"
    focus_pane_right = "alt+l"

    new_tab = ["prefix+c", "prefix+n"]
    previous_tab = ["prefix+p", "alt+shift+h"]
    next_tab = "alt+shift+l"

    split_vertical = ["prefix+v", "alt+n"]

    swap_pane_left = "prefix+h"
    swap_pane_down = "prefix+j"
    swap_pane_up = "prefix+k"
    swap_pane_right = "prefix+l"

    resize_mode = ["prefix+r", "ctrl+n"]
  '';
}
