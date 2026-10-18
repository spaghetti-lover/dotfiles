-- Personal keybindings, loaded after Omarchy's defaults.
-- See current bindings: omarchy menu keybindings --print
-- Rebind an existing key with hl.unbind("<keys>") before o.bind(...).

-- Hyprland's PATH lacks Linuxbrew, so brew tools need their full path.
local brew = "/home/linuxbrew/.linuxbrew/bin/"

o.bind("SUPER + CTRL + Y", "File manager (Yazi)",
  "omarchy-launch-tui --app-id=org.omarchy.yazi env FZF_DEFAULT_COMMAND='fd --hidden' " .. brew .. "yazi")
