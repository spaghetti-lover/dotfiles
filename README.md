# Dotfiles

Shared app configs and packages for macOS and Omarchy. Both use Homebrew (Linuxbrew on Omarchy); Linux also requires an existing Omarchy installation.

```sh
make stow-check  # preview links
make install     # install packages, link configs, run module hooks
make install MODULES="tmux yazi"  # just these modules
```

`make stow` links configs only; `make unstow` removes managed links without restoring backups. Conflicts are saved in `~/.local/state/dotfiles-backups/`. Run `make help` for every command and `make modules` for what runs where. Neither platform changes your login shell.

## Modules

Each `modules/<name>/` holds an app's config, laid out as it sits in `$HOME`, plus a `module.conf`:

```
# modules/tmux/module.conf
link .tmux.conf                                   # modules/tmux/.tmux.conf -> ~/.tmux.conf
link@omarchy .tmux.conf|.config/tmux/tmux.conf    # source|destination when they differ
brew sesh                                         # both platforms
brew@macos tmux                                   # Omarchy ships it
```

One entry per line: `<kind>[@macos|@omarchy] <value>`. Kinds:

- `link` — `source[|destination]`, relative to the module and to `$HOME`.
- `brew`, `cask`, `tap`, `go`, `cargo` — become Brewfile entries; casks are skipped on Omarchy. `make packages-print` shows the result.
- `platforms` — limit the whole module, e.g. `platforms macos`.

An optional `install.sh` runs after packages and links. To add an app, create its folder with a `module.conf`; to add a tool with no config, add a `brew` line to `modules/cli/module.conf`. Mark packages Omarchy already ships with `@macos`.

## Shell

`modules/shell/.config/shell/*.sh` holds env, aliases and functions sourced by both `.bashrc` (Omarchy) and `.zshrc` (macOS), so keep them valid in bash and zsh. Shell-specific setup stays in `modules/bash` and `modules/zsh`; Omarchy's own bash aliases (`ls`, `n`, `c`, `cx`, `cy`, `t`) win on Linux.

The linker also creates `~/dotfiles`, so helper scripts work wherever the checkout lives. macOS window controls need yabai/skhd permissions; see [yabai](modules/yabai/README.md).
