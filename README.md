## Hi 😂

Every day I am using vim, and I feel like I can learn new things every day.
So please don't wonder or judge why this repo has many commits.

This repo belong to [Kunkka](https://github.com/kunkka19xx). I just cloned and added some personal config

### Main tools

- homebrew (pkgs manager)
- nvim (code editor)
- tmux (term multiplexer)
- ghostty (terminal emulator)
- aerospace is a window manager for macos (i3 like)
- zshell
- GNU stow is a symlink management tool
- zoxide (smarter `cd`: `z <part-of-path>` jumps, `zi` picks with fzf)
- eza (better `ls`: icons and git status; aliased to `ls`, `lsa`, `lt`, `lta`)
- mise (per-project runtime versions, replaces SDKMAN here)
- btop (resource monitor), fastfetch (system info)
- glab (GitLab CLI, needs a one-time `glab auth login`)

_Note_: Some tools I also recommend: lazydocker, bat, fzf, autocompletion, ... (can be installed with brew)

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

Two steps still need a human afterwards, and `make install` reminds you of both:

```shell
make macos-shortcuts   # see Keybindings below; not optional
```

...and launching Karabiner-Elements once to grant Input Monitoring.

Run `make help` to see every target.

## Repo layout

```
modules/     one directory per tool -- this is the stow directory
install/     Brewfile + bootstrap.sh
docs/        cheat sheets
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
- Need to install delve for debugging: `brew install delve`
- Need ripgrep for telescope live grep

```shell
brew install ripgrep
```

- Need wget to help mason to download zip,... from internet

```shell
brew install wget
```

## Keybindings

Window management, terminal and tmux follow an
[Omarchy](https://omarchy.org/manual/navigation)-style keyboard layer, with **⌘ as Super**.
Full cheat sheet: [docs/keybindings.md](./docs/keybindings.md).

Because AeroSpace grabs ⌘ combos globally, the macOS menu commands it displaces (Find, Open,
Save, Print, Zoom, ...) are re-bound onto plain Ctrl. Run this once per machine —
it is not optional, since ⌘S is the scratchpad toggle and Save has nowhere else to go:

```shell
cd ~/dotfiles
make macos-shortcuts        # make macos-shortcuts-reset to undo
```

Apps are listed by bundle ID in `modules/aerospace/bin/macos-app-shortcuts.sh`; add yours there as
you install them, or they keep no Save shortcut at all.

⌘1…⌘9 are workspace switches, so browser tabs move to ⌥1…⌥9. That one binding needs
Karabiner-Elements: launch it once and grant Input Monitoring, and the stowed
`modules/karabiner/.config/karabiner/karabiner.json` does the rest. macOS will also ask once to let
it control your browser.

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

### Nvim setup

- I use lazy to manage plugins, you can use packer
- To sync or update plugins

```shell
:Lazy sync
:Lazy update
```

- I think it's better if we keep our settings at a simple level, don't set many things
  that you rarely use or you can achieve this purpose by some simple commands.

- Check log lsp:

```shell
nvim ~/.local/state/nvim/lsp.log
```

or

```
:LspLog
```

- Vim help is so helpful. Use it as much as you can
  example

```
:help Mason
```

## Integrate local LLMs with nvim

- Local models: use ollama
  [ollama](https://ollama.com/)

- Code suggestion: use super Maven
  [supermaven](https://supermaven.com/)

- My nvim - llms integration settings are in:
  [llms](./modules/nvim/.config/nvim/lua/plugins/llms.lua)

- The open-webui compose file lives in [extras/open-webui](./extras/open-webui/docker-compose.yaml)

## Colima

- symlink for docker.sock (use test container or act)

  ```sh
  sudo ln -s ~/.colima/default/docker.sock /var/run/docker.sock
  ```

## Apple / mobile development

Swift, iOS and macOS setup in nvim: [docs/apple-dev.md](./docs/apple-dev.md), with the brew
packages in [install/apple-dev.sh](./install/apple-dev.sh).
