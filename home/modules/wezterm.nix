{ inputs, ... }: {
  programs.wezterm = {
    enable = true;
    package = inputs.unstable.legacyPackages.x86_64-linux.wezterm;

    extraConfig = ''
      local wezterm = require 'wezterm'

      local config = {}

      config.font = wezterm.font 'monospace'
      config.color_scheme = "Tomorrow Night"
      -- config.window_background_image = '/home/ari/Desktop/wp.jpg'
      config.window_background_image_hsb = {
        brightness = 0.1
      }
      -- config.window_background_opacity = 0.92
      config.enable_tab_bar = false
      config.window_decorations = "RESIZE"

      local act = wezterm.action

      local function isViProcess(pane) 
        return pane:get_foreground_process_name():find('n?vim') ~= nil
      end

      local function in_tmux_session()
        local term = os.getenv("TERM")
        wezterm.log_warn(term)
        if term and (term:find("tmux") or term:find("screen")) then
          return true
        end
        return false
      end

      local function conditionalActivatePane(window, pane, pane_direction, tmux_seq)
        if isViProcess(pane) then
          window:perform_action(
            -- This should match the keybinds you set in Neovim.
            act.SendKey({ key = vim_direction, mods = 'ALT' }),
            pane
          )
        elseif true then -- in_tmux_session() then
          window:perform_action(wezterm.action{SendString=tmux_seq}, pane)
        else
          window:perform_action(wezterm.action{ActivatePaneDirection=pane_direction}, pane)
        end
      end

      wezterm.on('ActivatePaneDirection-right', function(window, pane)
        conditionalActivatePane(window, pane, 'Right', '\x1b\x6c')
      end)
      wezterm.on('ActivatePaneDirection-left', function(window, pane)
        conditionalActivatePane(window, pane, 'Left', '\x1b\x68')
      end)
      wezterm.on('ActivatePaneDirection-up', function(window, pane)
        conditionalActivatePane(window, pane, 'Up', '\x1b\x6b')
      end)
      wezterm.on('ActivatePaneDirection-down', function(window, pane)
        conditionalActivatePane(window, pane, 'Down', '\x1b\x6a')
      end)
      wezterm.on('ToggleZenMode', function(window, pane)
        local overrides = window:get_config_overrides() or {}
        if overrides.is_zen_mode then
          overrides = {}
        else
          overrides.is_zen_mode = true
          overrides.window_padding = {
            left = '40cell',
            right = '40cell',
            top = 0,
            bottom = 0,
          }
          overrides.window_background_image = ' '
          overrides.colors = { background = '#22272E' }
        end
        window:set_config_overrides(overrides)
      end)

      config.debug_key_events = true

      config.keys = {
        { key = 'h', mods = 'ALT', action = wezterm.action{EmitEvent='ActivatePaneDirection-left'} },
        { key = 'j', mods = 'ALT', action = wezterm.action{EmitEvent='ActivatePaneDirection-down'} },
        { key = 'k', mods = 'ALT', action = wezterm.action{EmitEvent='ActivatePaneDirection-up'} },
        { key = 'l', mods = 'ALT', action = wezterm.action{EmitEvent='ActivatePaneDirection-right'} },
        { key = 'i', mods = 'ALT', action = wezterm.action{EmitEvent='ToggleZenMode'} },
      }

      config.set_environment_variables = {
        TERMINFO_DIRS = '/home/user/.nix-profile/share/terminfo',
        VTE_VERSION = '6003',
      }

      return config
    '';
  };
}
