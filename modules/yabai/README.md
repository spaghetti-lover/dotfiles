# yabai

The window manager half of the yabai setup. Keys are in `../skhd`.

Stow-ignored (`bin/`, `README.md`), so `yabairc` and the scripts reach `$HOME`
as `~/.config/yabai/yabairc` and are called from there by absolute path.

## Operational notes

**Run `make wm-aerospace` before the first `make stow`.** skhd hot-loads its
config, so `~/.config/skhd/skhdrc` goes live the moment stow creates the
symlink -- and if AeroSpace is still up at that point, both are grabbing every
`cmd` chord at once. Stopping the services first means stowing does nothing
until you deliberately `make wm-yabai`.

**Re-run `make yabai-sa` after every `brew upgrade yabai`.** The sudoers rule
pins the binary's SHA-256, so an upgrade invalidates it and `--load-sa` starts
failing silently. `docs/yabai.md` covers what that costs.

**`make yabai-spaces`** re-provisions and re-labels the spaces by hand, which is
what to reach for if `cmd-1..9` starts landing in the wrong place after a
display change.
