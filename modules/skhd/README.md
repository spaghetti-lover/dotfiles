# skhd

The keybinding half of the yabai setup. The window manager half is `../yabai`.

Stow-ignored (`README.md`), so only `skhdrc` reaches `$HOME`, as
`~/.config/skhd/skhdrc` -- the first path skhd looks in.

## Operational notes

**`skhd --reload` after editing `skhdrc` in the repo.** The hot-load watches the
file, but stow installs a *symlink*, and FSEvents on a symlink does not reliably
fire when the target changes. Service mode's `escape` does this too.

**`bin/` holds only `browser-tab.sh`**, which backs the opt-1..9 browser tab
bindings that used to live in Karabiner-Elements. The TUI launchers
(`cmd-ctrl-t` btop, `cmd-ctrl-u` disk usage) run no script of their own -- they
point at the ghostty config files in `../ghostty`, which is also what places
them: the title each config sets is what `../yabai`'s `tui_float` rule matches.

**skhd grabs `cmd` globally**, so the macOS menu commands it displaces (Save,
Open, Find, Print, ...) stay displaced. Rebind by hand in System Settings >
Keyboard > Keyboard Shortcuts if you miss one.
