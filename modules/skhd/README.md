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

**`bin/` holds only `browser-tab.sh`**, which backs the opt-1..9 browser tab
bindings that used to live in Karabiner-Elements. The TUI launchers
(`cmd-ctrl-t` btop, `cmd-ctrl-u` disk usage) run no script of their own -- they
point at the ghostty config files in `../ghostty`, which is also what places
them: the title each config sets is what `../yabai`'s `tui_float` rule matches.

**skhd grabs `cmd` globally**, so the macOS menu commands it displaces (Save,
Open, Find, Print, ...) stay displaced. The `macos-app-shortcuts.sh` helper that
used to re-bind them onto plain Ctrl lived in the deleted `../aerospace/bin/` and
is gone; rebind by hand in System Settings > Keyboard > Keyboard Shortcuts if you
miss one.
