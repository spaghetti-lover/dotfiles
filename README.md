## Hi 😂

Every day I am using vim, and I feel like I can learn new things every day.
So please don't wonder or judge why this repo has many commits.

This repo belong to [Kunkka](https://github.com/kunkka19xx). I just cloned and added some personal config

### Main tools

- homebrew (pkgs manager)
- nvim (code editor)
- tmux (term multiplexer)
- ghostty (terminal emulator)
- zshell
- GNU stow is a symlink management tool
- zoxide (smarter `cd`: `z <part-of-path>` jumps, `zi` picks with fzf)
- eza (better `ls`: icons and git status; aliased to `ls`, `lsa`, `lt`, `lta`)
- mise (per-project runtime versions, replaces SDKMAN here)
- try (date-stamped experiment dirs under `~/Projects/tries`: plain `try` browses them,
  `try redis` jumps to or creates one, `try .` makes a worktree of the current repo)
- btop (resource monitor), fastfetch (system info), dua (disk usage TUI; `⌘⌃U` walks the whole
  file system, biggest first — needs Ghostty in Full Disk Access to see everything)
- glab (GitLab CLI, needs a one-time `glab auth login`)

_Note_: Some tools I also recommend: lazydocker, bat, fzf, autocompletion, ... (can be installed with brew)


## Window manager

yabai + skhd, with real window groups, real sticky windows and mouse
drag/resize. skhd grabs `cmd` combinations globally, so no other window
manager may run alongside it.

## Install

You need [Homebrew](https://docs.brew.sh/Installation) first:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then the whole machine is one command:

```shell
git clone <this-repo> ~/Projects/dotfiles
ln -s ~/Projects/dotfiles ~/dotfiles     # some configs hardcode ~/dotfiles
cd ~/dotfiles && make install
```

`make install` installs everything in `install/Brewfile`, symlinks every module into `$HOME` with
stow, and runs each module's install hook. It is idempotent — re-run it whenever you pull.

Run `make help` to see every target.

## Repo layout

```
modules/     one directory per tool -- this is the stow directory
install/     Brewfile + bootstrap.sh
extras/      things that are not dotfiles (open-webui compose file)
```

### Adding a module

Create `modules/<tool>/` and put the payload at its root, mirroring where the files live in
`$HOME`. Nothing else needs editing — the Makefile discovers modules by globbing `modules/*`.

| Path in the module | Stowed into `$HOME`? | What it is |
| ------------------ | -------------------- | ---------- |
| `.zshrc`, `.config/...` | yes | The payload |
| `bin/` | no | Helper scripts the config calls at runtime |
| `share/` | no | Assets (sounds, images) |
| `install.sh` | no | Post-stow hook, run if executable |
| `README.md` | no | Notes about that tool |

So a new `modules/foo/.config/foo/config` becomes `~/.config/foo/config` on the next `make stow`,
while `modules/foo/bin/helper.sh` stays in the repo. Check before committing:

```shell
make stow-check     # dry run, changes nothing
make stow
```

`make unstow` removes the links again; `make restow` does both, which is what you want after
renaming or deleting a config file.

For more information about GNU stow: [link](https://www.gnu.org/software/stow/)

## Note:

- You need Ghostty/iTerm,...(not default macos terminal) because this terminal can not represent right theme
- Nerd font for view icon, text, folder, ... [link](https://www.nerdfonts.com/)
- herdr reads its colours from Ghostty (`[theme] name = "terminal"`), so the Ghostty theme sets both

## Keybindings

Window management, terminal and tmux follow an
[Omarchy](https://omarchy.org/manual/navigation)-style keyboard layer, with **⌘ as Super**.
The bindings themselves are in `modules/skhd/.config/skhd/skhdrc`.

⌘1…⌘9 are workspace switches, so browser tabs move to ⌥1…⌥9, handled by skhd in browsers only
(`modules/skhd/bin/browser-tab.sh`). macOS will ask once to let skhd control your browser.

### Backup pkgs by brew

```shell
cd ~/dotfiles

# Install packages from Brewfile (on new system)
# This also refreshes Brewfile.lock.json
make brew-install

# Check if installed packages match Brewfile
make brew-check

# Update Brewfile from what is installed now
# Careful: this overwrites the Brewfile, so only run it on a set-up machine
make brew-update

# Remove packages not in Brewfile
make brew-clean
```

Linux

- skip un-supported packs

```shell
brew bundle check --file=install/Brewfile
sed -i '/cask /d' install/Brewfile
```

### Docker compose

Homebrew installs compose as a CLI plugin, but Docker does not scan its directory by default.
To make `docker compose ...` work (not just the standalone `docker-compose`), add this to
`~/.docker/config.json`:

```json
"cliPluginsExtraDirs": ["/opt/homebrew/lib/docker/cli-plugins"]
```

## Nvim

[LazyVim](https://www.lazyvim.org/), with Omarchy's overlays on top. `:Lazy sync` updates plugins;
`:LazyExtras` is where language support and AI completion get switched on — nothing is enabled by
default beyond neo-tree, so a fresh clone has no Go or TypeScript LSP until you pick the `lang.*`
extras you want. `ai.supermaven` and `ai.copilot` live there too.

How to launch it: ⌘⇧N, or `nvim` in any shell.

For local models, [ollama](https://ollama.com/); the open-webui compose file is in
[extras/open-webui](./extras/open-webui/docker-compose.yaml).

## Colima

- symlink for docker.sock (use test container or act)

  ```sh
  sudo ln -s ~/.colima/default/docker.sock /var/run/docker.sock
  ```
