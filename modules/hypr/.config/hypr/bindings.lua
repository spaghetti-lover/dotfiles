-- Personal keybindings, loaded after Omarchy's defaults.
-- See current bindings: omarchy menu keybindings --print
-- Rebind an existing key with hl.unbind("<keys>") before o.bind(...).

-- Hyprland's PATH lacks Linuxbrew, so brew tools need their full path.
local brew = "/home/linuxbrew/.linuxbrew/bin/"

-- Yazi also shells out to brew tools (7zz for archive previews), so give it brew's PATH.
o.bind("SUPER + CTRL + Y", "File manager (Yazi)",
  "omarchy-launch-tui --app-id=org.omarchy.yazi env PATH=" .. brew .. ":$PATH FZF_DEFAULT_COMMAND='fd --hidden' " .. brew .. "yazi")
-- Open Yazi maximized, like SUPER + ALT + F (macOS uses TUI.fullscreen).
o.window("^org\\.omarchy\\.yazi$", { maximize = true })
