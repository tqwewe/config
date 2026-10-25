{
  config,
  lib,
  pkgs,
  ...
}:
let
  # herdr's notification sounds, so finished agents ding exactly like they did there.
  herdrSound =
    name: hash:
    pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/herdrdev/herdr/v0.9.3/assets/sounds/${name}.mp3";
      inherit hash;
    };

  agentHook = pkgs.writeShellApplication {
    name = "kitty-agent-hook";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./kitty-agent-hook.sh;
  };

  agentHookEvents = [
    "SessionStart"
    "SessionEnd"
    "UserPromptSubmit"
    "PreToolUse"
    "PostToolUse"
    "Notification"
    "Stop"
  ];

  # Paints over a snapshot of the focused pane with falling-sand. kitty marks
  # wrapped lines with a lone \r (real line ends are \r\n), which falling-sand
  # needs as real row breaks.
  annotate = pkgs.writeShellScript "kitty-annotate" ''
    ${lib.getExe pkgs.gnused} -e 's/\r$//' -e 's/\r/\n/g' | "$HOME/.cargo/bin/falling-sand" -a
  '';
  globalKeys = {
    "alt+n" = "kitten launch.py --location=split";
    "alt+h" = "kitten focus.py left";
    "alt+j" = "neighboring_window down";
    "alt+k" = "neighboring_window up";
    "alt+l" = "kitten focus.py right";
    "alt+shift+h" = "previous_tab";
    "alt+shift+l" = "next_tab";
    "alt+f" = "toggle_layout stack";
  };

  # In a mode, kitty swallows an unbound key with a bell instead of running its
  # normal binding, so the global keys are mapped in each mode too, leaving it first.
  modeGlobalKeys =
    mode:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        key: action: "map --mode ${mode} ${key} combine : pop_keyboard_mode : ${action}"
      ) globalKeys
    );

  annotateAction = "launch --type=overlay --var annotate=1 --stdin-source=@screen --stdin-add-formatting --stdin-add-line-wrap-markers ${annotate}";

  # Every pane runs in a shpool session; `kitty-shpool pick` resumes one, e.g.
  # `ssh desktop -t kitty-shpool pick` from the laptop.
  kittyShpool = pkgs.writeShellApplication {
    name = "kitty-shpool";
    runtimeInputs = [
      pkgs.shpool
      pkgs.jq
      pkgs.fzf
      pkgs.procps
      pkgs.gawk
      config.programs.kitty.package
    ];
    text = builtins.readFile ./kitty-shpool.sh;
  };
in
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
      shell = lib.getExe kittyShpool;
      allow_remote_control = "yes";
      listen_on = "unix:@kitty";

      tab_bar_edge = "top";
      tab_bar_style = "custom";
      tab_powerline_style = "round";
      tab_bar_min_tabs = 1;
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

    keybindings = globalKeys // {
      "ctrl+t>n" = "kitten launch.py --type=tab";
      "ctrl+t>x" = "kitten close.py tab";
      "ctrl+p>x" = "kitten close.py";
      "ctrl+shift+w" = "kitten close.py";
      "ctrl+t>r" = "kitten restore.py";
      "ctrl+t>s" = "launch --type=tab ${lib.getExe kittyShpool} pick";
      "ctrl+p>d" = "kitten launch.py --location=hsplit";
      "ctrl+p>r" = "kitten launch.py --location=vsplit";
      "ctrl+p>a" = "kitten annotate.py";
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
      map --mode move ctrl+k pop_keyboard_mode
      map --mode move ctrl+n combine : pop_keyboard_mode : push_keyboard_mode resize
      ${modeGlobalKeys "move"}

      map --new-mode resize --on-unknown end ctrl+n
      map --mode resize h kitten resize.py left 5
      map --mode resize l kitten resize.py right 5
      map --mode resize j kitten resize.py down 5
      map --mode resize k kitten resize.py up 5
      map --mode resize esc pop_keyboard_mode
      map --mode resize enter pop_keyboard_mode
      map --mode resize ctrl+n pop_keyboard_mode
      map --mode resize ctrl+k combine : pop_keyboard_mode : push_keyboard_mode move
      ${modeGlobalKeys "resize"}
    '';

    themeFile = "MaterialDark";
  };

  # home-manager reloads kitty with `pkill kitty`, which also matches (and, via
  # SIGUSR1, kills) every pane's kitty-shpool wrapper, closing kitty on switch.
  xdg.configFile."kitty/kitty.conf".onChange = lib.mkForce ''
    ${pkgs.procps}/bin/pkill -USR1 -u $USER '^(\.kitty-wrapped|kitty)$' || true
  '';
  xdg.configFile."kitty/resize.py".source = ./kitty-resize.py;
  xdg.configFile."kitty/focus.py".source = ./kitty-focus.py;
  xdg.configFile."kitty/launch.py".source = ./kitty-launch.py;
  xdg.configFile."kitty/restore.py".source = pkgs.replaceVars ./kitty-restore.py {
    shpool = lib.getExe pkgs.shpool;
    kittyShpool = lib.getExe kittyShpool;
  };
  xdg.configFile."kitty/close.py".source = pkgs.replaceVars ./kitty-close.py {
    shpool = lib.getExe pkgs.shpool;
  };
  xdg.configFile."kitty/annotate.py".source = pkgs.replaceVars ./kitty-annotate.py {
    inherit annotateAction;
  };
  xdg.configFile."kitty/tab_bar.py".source = pkgs.replaceVars ./kitty-tab-bar.py {
    pwPlay = "${pkgs.pipewire}/bin/pw-play";
    doneSound = herdrSound "done" "sha256-y5yTSSyAjjOUbtrCq1kVdYJn5lkUvEt5Slym3G5lV0E=";
    requestSound = herdrSound "request" "sha256-RMB3ziigpIzsKdogS+tif9FxQOW94fktuuzz1Hi92m8=";
  };

  # settings.json is also written by Claude Code itself, so merge our hooks into it
  # rather than owning the file. Also drops the hook herdr left behind.
  home.activation.claudeKittyHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    [ -s "$settings" ] || echo '{}' > "$settings"
    tmp="$(mktemp "$settings.XXXXXX")"
    ${lib.getExe pkgs.jq} \
      --arg hook "${lib.getExe agentHook}" \
      --argjson events '${builtins.toJSON agentHookEvents}' '
        def ours: (.command // "") | test("kitty-agent-hook|herdr-agent-state\\.sh");
        .hooks = (.hooks // {})
        | .hooks |= with_entries(
            .value |= (map(.hooks |= map(select(ours | not))) | map(select(.hooks | length > 0)))
          )
        | .hooks |= with_entries(select(.value | length > 0))
        | reduce $events[] as $event (.;
            .hooks[$event] += [
              (if $event == "Notification" then { matcher: "permission_prompt|elicitation_dialog" } else {} end)
              + { hooks: [{ type: "command", command: "\($hook) \($event)", timeout: 5 }] }
            ]
          )
      ' "$settings" > "$tmp" && run mv -f "$tmp" "$settings" || rm -f "$tmp"
  '';

  home.packages = [ kittyShpool ];

  services.shpool = {
    enable = true;
    settings = {
      prompt_prefix = "";
      motd = "never";
      # Copied into a session's shell when it's created, so kitty's shell
      # integration and colours work in panes. Ignored on later attaches.
      forward_env = [
        "COLORTERM"
        "KITTY_INSTALLATION_DIR"
        "KITTY_LISTEN_ON"
        "KITTY_PID"
        "KITTY_PUBLIC_KEY"
        "KITTY_WINDOW_ID"
        "TERMINFO"
      ];
    };
  };

  # Restarting the daemon kills every session, so a switch that changes the
  # service (e.g. a shpool update) leaves the running one until the next login.
  systemd.user.services.shpool.Unit.X-SwitchMethod = "keep-old";
}
