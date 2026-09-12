# skhd

The keybinding half of the yabai setup. The window manager half is
`../yabai`; together they do what `../aerospace/.config/aerospace/aerospace.toml`
does on its own.

Stow-ignored (`README.md`), so only `skhdrc` reaches `$HOME`, as
`~/.config/skhd/skhdrc` -- the first path skhd looks in.

## Operational notes

**Run `make wm-aerospace` before the first `make stow`.** See `../yabai/README.md`
-- skhd hot-loads, so the config goes live the instant it is stowed.

**`skhd --reload` after editing `skhdrc` in the repo.** The hot-load watches the
file, but stow installs a *symlink*, and FSEvents on a symlink does not reliably
fire when the target changes. Service mode's `escape` does this too.

**This module has no `bin/`.** The launchers point at
`../aerospace/bin/{copy-url,localsend-share,herdr-keys}.sh` and the ghostty
config files in `../ghostty`, so the two window managers share one copy of each
rather than drifting apart. They move into a module of their own only if
AeroSpace is deleted.

**`macos-app-shortcuts.sh` is still required**, and still lives in
`../aerospace/bin/`. skhd grabs `cmd` globally exactly as AeroSpace does, so the
displaced menu commands need the same treatment: `make macos-shortcuts`.
