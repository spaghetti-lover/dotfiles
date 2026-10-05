# Karabiner

`share/karabiner.json` defines the Omarchy modifier shortcuts. Karabiner owns
`~/.config/karabiner/karabiner.json` and rewrites it when settings change, so
this module does not stow that file.

Run `./modules/karabiner/install.sh` after editing the template. The hook
replaces the managed Omarchy rules, removes the old Chrome-wide Control rule,
preserves other Karabiner settings and rules, and reloads the running service.
`make install` runs the hook too.
