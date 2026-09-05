local wezterm = require("wezterm")
local config = wezterm.config_builder()
local io = require("io")
local os = require("os")
local brightness = 0.03

-- image setting
local home = os.getenv("HOME")
local background_folder = home .. "/bg"
local function pick_random_background(folder)
    local handle = io.popen('ls "' .. folder .. '"')
    if handle ~= nil then
        local files = handle:read("*a")
        handle:close()

        local images = {}
        for file in string.gmatch(files, "[^\n]+") do
            table.insert(images, file)
        end

        if #images > 0 then
            return folder .. "/" .. images[math.random(#images)]
        else
            return nil
        end
    end
end

config.window_background_image_hsb = {
    -- Darken the background image by reducing it
    brightness = brightness,
    hue = 1.0,
    saturation = 0.8,
}

-- default background
local bg_image = home .. "/.config/nvim/bg/bg.jpg"

config.window_background_image = bg_image
-- end image setting

-- window setting
config.window_background_opacity = 0.90
config.macos_window_background_blur = 85
config.window_padding = {
    left = 18,
    right = 18,
    top = 12,
    bottom = 12,
}

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("Inconsolata Nerd Font Mono", { weight = "Medium", stretch = "Expanded" })
config.font_size = 20

config.window_decorations = "RESIZE"
config.enable_tab_bar = false

-- Option must arrive as Meta so tmux sees Alt+Enter / Alt+1-9 (Omarchy's
-- terminal layer). Without this the whole Alt layer in .tmux.conf is dead.
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Shift+Enter is indistinguishable from Enter over plain xterm encoding, so
-- tmux's Alt+Shift+Enter (split beside) never fires. The Kitty keyboard
-- protocol disambiguates it; tmux opts in with `extended-keys on`.
config.enable_kitty_keyboard = true

-- never ask for confirmation when closing a window/tab/pane
config.window_close_confirmation = "NeverPrompt"

config.window_frame = {
    -- border_left_width = "0.18cell",
    -- border_right_width = "0.18cell",
    -- border_bottom_height = "0.08cell",
    -- border_top_height = "0.08cell",
    -- border_left_color = "pink",
    -- border_right_color = "pink",
    -- border_bottom_color = "pink",
    -- border_top_color = "pink",
}

-- keys
config.keys = {
    {
        key = "b",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            bg_image = pick_random_background(background_folder)
            if bg_image then
                window:set_config_overrides({
                    window_background_image = bg_image,
                })
                wezterm.log_info("New bg:" .. bg_image)
            else
                wezterm.log_error("Could not find bg image")
            end
        end),
    },
    {
        key = "L",
        mods = "CTRL|SHIFT",
        action = wezterm.action.OpenLinkAtMouseCursor,
    },
    {
        key = ">",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            brightness = math.min(brightness + 0.01, 1.0)
            window:set_config_overrides({
                window_background_image_hsb = {
                    brightness = brightness,
                    hue = 1.0,
                    saturation = 0.8,
                },
                window_background_image = bg_image,
            })
        end),
    },
    {
        key = "<",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            brightness = math.max(brightness - 0.01, 0.01)
            window:set_config_overrides({
                window_background_image_hsb = {
                    brightness = brightness,
                    hue = 1.0,
                    saturation = 0.8,
                },
                window_background_image = bg_image,
            })
        end),
    },
    {
        key = "w",
        mods = "CMD",
        action = wezterm.action.CloseCurrentTab({ confirm = false }),
    },
    {
        key = "w",
        mods = "CTRL|SHIFT",
        action = wezterm.action.CloseCurrentTab({ confirm = false }),
    },
    {
        key = "w",
        mods = "CMD|SHIFT",
        action = wezterm.action.CloseCurrentPane({ confirm = false }),
    },
    -- AeroSpace owns CMD+t now (toggle float), so New Tab moves here.
    {
        key = "t",
        mods = "CTRL|SHIFT",
        action = wezterm.action.SpawnTab("CurrentPaneDomain"),
    },
}

-- others
config.default_cursor_style = "BlinkingUnderline"
config.cursor_thickness = 2
config.max_fps = 120
return config
