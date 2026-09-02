## Hi 😂

Every day I am using vim, and I feel like I can learn new things every day.
So please don't wonder or judge why this repo has many commits.

This repo belong to [Kunkka](https://github.com/kunkka19xx). I just cloned and added some personal config

### Main tools

- homebrew (pkgs manager)
- nvim (code editor)
- tmux (term multiplexer)
- ghostty and wezterm for terminal emulator
- aerospace is a window manager for macos (i3 like)
- zshell
- GNU stow is a symlink management tool
- zoxide (smarter `cd`: `z <part-of-path>` jumps, `zi` picks with fzf)
- eza (better `ls`: icons and git status; aliased to `ls`, `lsa`, `lt`, `lta`)
- mise (per-project runtime versions, replaces SDKMAN here)
- btop (resource monitor), fastfetch (system info)
- glab (GitLab CLI, needs a one-time `glab auth login`)

_Note_: Some tools I also recommend: lazydocker, bat, fzf, autocompletion, ... (can be installed with brew)

## Installing steps

- You need a package manager, if you are using macos, **homebrew** is a good one.

### Homebrew

[link](https://docs.brew.sh/Installation)

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### After installing homebrew let's rock

```shell
brew install nvim
brew install tmux
brew install --cask ghostty
brew install --cask wezterm
brew install stow
brew install zsh
```

### Where should your settings be stored?

With stow you can create symlink from a directory to a target directory.
So ideally, all settings shoul be in a directory, for example `~/dotfiles`

```shell
cd
mkdir dotfiles
```

After that, create dir tree structure for each tool with same structure as in its docs.
For instance, with nvim, you should place your configs in `~/.config/nvim`

-> Create dir structure like this in dotfiles

```shell
cd ~/dotfiles
mkdir -p nvim/.config/nvim
```

Do the same steps with the other tools.
Then run this to create symlinks

```shell
stow nvim
stow zsh
stow aerospace
stow tmux
stow wezterm
stow ghostty
stow karabiner
```

for more information about gnustow: [link](https://www.gnu.org/software/stow/)

## Note:

- You need Iterm/Wezeterm,...(not default macos terminal) because this terminal can not represent right theme
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
cd ~/dotfiles/others
make macos-shortcuts        # make macos-shortcuts-reset to undo
```

Apps are listed by bundle ID in `others/macos-app-shortcuts.sh`; add yours there as you install
them, or they keep no Save shortcut at all.

⌘1…⌘9 are workspace switches, so browser tabs move to ⌥1…⌥9. That one binding needs
Karabiner-Elements: launch it once and grant Input Monitoring, and the stowed
`karabiner/.config/karabiner/karabiner.json` does the rest. macOS will also ask once to let it
control your browser.

### Backup pkgs by brew

Use the Makefile in `others/` for easy management:

```shell
cd ~/dotfiles/others

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

# Show all available commands
make help
```

Linux

- skip un-supported packs

```shell
brew bundle check --file=Brewfile
sed -i '/cask /d' Brewfile
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
  [llms](./nvim/.config/nvim/lua/plugins/llms.lua)

## Colima

- symlink for docker.sock (use test container or act)

  ```sh
  sudo ln -s ~/.colima/default/docker.sock /var/run/docker.sock
  ```
