# Dotfiles

Shared app configs for macOS and Omarchy. macOS requires Homebrew; Linux requires an existing Omarchy installation.

```sh
make stow-check  # preview
make install     # install macOS packages, link configs, run macOS hooks
```

`make stow` links configs only; `make unstow` removes managed links without restoring backups. Conflicts are saved in `~/.local/state/dotfiles-backups/`. Linux uses installed apps and Bash; macOS uses Zsh. Neither changes your login shell.

`modules/<app>/` holds configs and helpers. `install/links/` maps `repo source|home destination`, with shared and platform lists. Add configs there. The linker creates `~/dotfiles` for helper scripts, so the checkout can live elsewhere.

Run `make help` for commands. macOS window controls need yabai/skhd permissions; see [yabai](modules/yabai/README.md).
