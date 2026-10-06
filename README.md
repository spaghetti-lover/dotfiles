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

yabai + skhd, with real window groups and real sticky windows. skhd grabs `cmd` combinations globally, so no other window
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
[Omarchy](https://omarchy.org/manual/navigation)-style keyboard layer, with **⌘ as Super**
and **Control as Ctrl**. Global bindings live in `modules/skhd/.config/skhd/skhdrc`;
Karabiner handles physical ⌘ shortcuts that overlap app shortcuts.

⌘1…⌘9 are workspace switches, so browser tabs move to ⌥1…⌥9, handled by skhd in browsers only
(`modules/skhd/bin/browser-tab.sh`). macOS will ask once to let skhd control your browser.

In macOS GUI apps, Karabiner maps Ctrl+T/L/W/N/R/F/S/O/P/A/Z and Ctrl+Shift+T
to the corresponding ⌘ app shortcuts. ⌘T/F/L/S/O/W/Q run Omarchy window and
workspace actions instead of the macOS app actions. Copy, cut and paste remain
⌘C/X/V, matching Omarchy's Super+C/X/V; Ctrl+C remains an interrupt in terminals.
In Chrome, Ctrl+Alt+N opens Split View and Ctrl+Shift+A opens Tab Search, using
the requested chords. Chrome's native Ctrl+Tab and Ctrl+Shift+Tab already switch tabs.
In Chrome, Ctrl+click opens a link in a background tab. Karabiner presents Control
as Command during a click, then keeps Control for keyboard chords, including
Ctrl+Space for input switching and Ctrl+Tab for tab navigation.
TigerVNC and terminal apps receive unmodified Control, and TigerVNC receives
unmodified ⌘ as Linux Super. VS Code has its own context-aware Ctrl shortcuts
so its integrated terminal also receives raw Control (Ctrl+R already opens
Recent natively). Other GUI apps with embedded terminals use the GUI mappings.
After editing the Karabiner rules in `modules/karabiner/share/karabiner.json`,
run `./modules/karabiner/install.sh` to update Karabiner's app-owned config.

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
`:LazyExtras` is where language support and AI completion get switched on. Go, Python, DAP debugging,
Neotest, neo-tree, and project support are enabled in the dotfiles. Add other `lang.*` extras
for their language servers and debugger/test adapters. `ai.supermaven` and `ai.copilot` live there too.

The debug UI follows Gruvbox and the transparent editor background. Variables and watches sit
on the left; the REPL and program output sit below. LazyVim opens this UI when a session starts
and closes it when the program exits. Variable values appear at the end of source lines.

In a Go project, open a source file, set a breakpoint with `<leader>db`, and press `<leader>dc`.
Choose **Debug Package** to build the whole package, or use a project `.vscode/launch.json`
for a particular entry point, arguments, and environment. `<leader>dc` saves modified buffers
before launching; continuing an existing session does not save or rebuild the program.

| Key | Debug action |
| --- | --- |
| `<leader>db` / `<leader>dB` | Toggle breakpoint / conditional breakpoint |
| `<leader>dc` / `<leader>dC` | Run or continue / run to cursor |
| `<leader>dO` / `<leader>di` / `<leader>do` | Step over / into / out |
| `<leader>du` / `<leader>de` | Toggle debug UI / evaluate cursor or visual selection |
| `<leader>dt` | Terminate debug session |
| `<leader>td` | Save modified buffers and debug the nearest test |
| `<leader>tr` / `<leader>tt` | Run nearest test / tests in the file |
| `<leader>ts` / `<leader>to` / `<leader>tO` | Test summary / output / output panel |
| `gd` / `gr` / `gai` / `gao` | Definition / references / incoming calls / outgoing calls |

`<leader>` is Space. For test debugging, put the cursor inside a Go test, set a breakpoint,
and press `<leader>td`; then use the same debug controls. Test output stays closed during runs;
open it with `<leader>to`. In the debug panels, Enter expands a value, `e` edits it, and `w`
adds a watch. Code navigation uses the language server and does not start a debugger.

Mason installs `gopls`, Delve, and the Go formatting tools; Go itself must be on `PATH`.
For Python, Mason installs Pyright, Ruff, and `debugpy`. The same debug and test shortcuts
work in Python files. Neotest detects pytest or unittest in the project's Python environment;
install your test dependencies there. An activated virtual environment or a project `.venv`
is detected automatically; use `<leader>cv` to select another environment.

`gai` opens an incoming call tree; `gao` opens an outgoing call tree. Both use
[meow.yarn.nvim](https://github.com/retran/meow.yarn.nvim) with a code preview and your
current theme. The tree initially shows only direct callers or callees. Select a node and press `l`
to fetch deeper callers or callees; use `h` to collapse it or Tab to toggle it.
`zO` / `zC` expand / collapse already-fetched branches, not the entire project.
Press Enter to jump to the selected call site or definition and close the tree;
`gal` reopens the previous hierarchy root. Inside the tree, `K` / `J` start a new
incoming / outgoing tree from the selected node, Backspace returns to the previous root,
and `q` closes the view and restores your original source window, cursor, and scroll position.
These shortcuts work with Go's `gopls` and Python's Pyright.
Call trees show static code relationships, not the execution order of a running program.

Apply only the Neovim module with `stow -R -d modules -t "$HOME" nvim`, then restart Neovim.

How to launch it: ⌘⇧N, or `nvim` in any shell.

For local models, [ollama](https://ollama.com/); the open-webui compose file is in
[extras/open-webui](./extras/open-webui/docker-compose.yaml).

## Colima

- symlink for docker.sock (use test container or act)

  ```sh
  sudo ln -s ~/.colima/default/docker.sock /var/run/docker.sock
  ```
