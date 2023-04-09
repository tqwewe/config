{ inputs, ... }: {
  programs.wezterm = {
    enable = true;
    package = inputs.unstable.legacyPackages.x86_64-linux.wezterm;

    extraConfig = ''
        local wezterm = require 'wezterm'

        local config = {}

        config.font = wezterm.font 'monospace'
        config.color_scheme = "Tomorrow Night"
        config.window_background_image = '/home/ari/Desktop/wp.jpg'
        config.window_background_image_hsb = {
            brightness = 0.1
        }

        local act = wezterm.action
        
        local function isViProcess(pane) 
            -- get_foreground_process_name On Linux, macOS and Windows, 
            -- the process can be queried to determine this path. Other operating systems 
            -- (notably, FreeBSD and other unix systems) are not currently supported
            return pane:get_foreground_process_name():find('n?vim') ~= nil
            -- return pane:get_title():find("n?vim") ~= nil
        end
        
        local function conditionalActivatePane(window, pane, pane_direction, vim_direction)
            if isViProcess(pane) then
                window:perform_action(
                    -- This should match the keybinds you set in Neovim.
                    act.SendKey({ key = vim_direction, mods = 'ALT' }),
                    pane
                )
            else
                window:perform_action(act.ActivatePaneDirection(pane_direction), pane)
            end
        end
        
        wezterm.on('ActivatePaneDirection-right', function(window, pane)
            conditionalActivatePane(window, pane, 'Right', 'l')
        end)
        wezterm.on('ActivatePaneDirection-left', function(window, pane)
            conditionalActivatePane(window, pane, 'Left', 'h')
        end)
        wezterm.on('ActivatePaneDirection-up', function(window, pane)
            conditionalActivatePane(window, pane, 'Up', 'k')
        end)
        wezterm.on('ActivatePaneDirection-down', function(window, pane)
            conditionalActivatePane(window, pane, 'Down', 'j')
        end)
        
        config.keys = {
            { key = 'h', mods = 'ALT', action = act.EmitEvent('ActivatePaneDirection-left') },
            { key = 'j', mods = 'ALT', action = act.EmitEvent('ActivatePaneDirection-down') },
            { key = 'k', mods = 'ALT', action = act.EmitEvent('ActivatePaneDirection-up') },
            { key = 'l', mods = 'ALT', action = act.EmitEvent('ActivatePaneDirection-right') },
        }

        return config
    '';
  };
}
