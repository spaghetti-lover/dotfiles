# Dotfiles

## Requirements

- macOS: [Homebrew](https://brew.sh)
- Linux: an existing [Omarchy](https://omarchy.org) installation and [Homebrew](https://brew.sh)

## Install

```sh
git clone https://github.com/spaghetti-lover/dotfiles.git
cd dotfiles
make stow-check  # preview links and backups
make install     # install packages, link configs, run module hooks
```

To install only some modules:

```sh
make install MODULES="tmux yazi"
```

## Other commands

```sh
make stow     # link configs only
make unstow   # remove managed links
make modules  # list modules and the platforms they run on
make help     # list every command
```

Conflicting files are backed up to `~/.local/state/dotfiles-backups/`.

On macOS, grant yabai/skhd their permissions afterwards; see [yabai](modules/yabai/README.md).
