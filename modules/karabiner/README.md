# Karabiner

`share/karabiner.json` defines the Omarchy modifier shortcuts. Karabiner owns
`~/.config/karabiner/karabiner.json` and rewrites it when settings change, so
this module does not stow that file.

Run `./modules/karabiner/install.sh` after editing the template. The hook
replaces the managed Omarchy rules, removes the old Chrome-wide Control rule,
preserves other Karabiner settings and rules, and reloads the running service.
`make install` runs the hook too.

Chrome Ctrl+click uses a modifier rule: while Control is held with no other key,
Chrome sees Command, so clicking a link opens a new tab. Pressing a keyboard key
switches the held modifier back to Control, preserving Ctrl+Space, Ctrl+Tab and
the existing app shortcut rules. TigerVNC is unaffected.
