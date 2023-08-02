{ pkgs, ... }: {
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    extraConfig = ''
      # Open new splits in the same working directory
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Navigate panes with Alt-hjkl
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      set -g allow-passthrough on
      set -g @resurrect-capture-pane-contents on
      set-option -sa terminal-overrides ",xterm*:Tc"
    '';
    keyMode = "vi";
    mouse = true;
    newSession = true;
    plugins = with pkgs; [
      tmuxPlugins.nord
      tmuxPlugins.resurrect
      tmuxPlugins.yank
    ];
    prefix = "C-Space";
    terminal = "screen-256color";
  };
}
