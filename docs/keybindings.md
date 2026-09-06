# Keybindings

An [Omarchy](https://omarchy.org/manual/navigation)-style keyboard layer for macOS,
following <https://omarchy.org/manual/hotkeys>.

## Modifier map

| Omarchy | macOS     |
| ------- | --------- |
| Super   | ⌘ Command |
| Alt     | ⌥ Option  |
| Ctrl    | ⌃ Control |
| Shift   | ⇧ Shift   |

⌘ is Super because Omarchy needs six distinct modifier layers (`Super`, `Super+Shift`,
`Super+Ctrl`, `Super+Alt`, `Super+Ctrl+Alt`, `Super+Shift+Alt`). macOS exposes only four modifier
bits, and Ctrl/Alt/Shift are all needed as sub-modifiers — so a Karabiner "Hyper" key cannot work
here: Hyper is just ⌃⌥⌘ chorded together, which makes `Super+Alt` indistinguishable from `Super`.

AeroSpace grabs ⌘ combos globally. See [What ⌘ costs](#what--costs) below.

---

## Navigating

| Keys                 | Action                                                                |
| -------------------- | --------------------------------------------------------------------- |
| `⌘ ←↓↑→`             | Move focus (cursor warps to the new window)                           |
| `⌘⇧ ←↓↑→`            | Swap window                                                           |
| `⌥ Tab` / `⌥⇧ Tab`   | Cycle windows                                                         |
| `⌃⌥ Tab` / `⌃⌥⇧ Tab` | Cycle monitors                                                        |
| `⌘ 1`…`9`            | Jump to workspace                                                     |
| `⌘ Tab` / `⌘⇧ Tab`   | Next / previous workspace                                             |
| `⌘⌃ Tab`             | Former workspace                                                      |
| `⌘⇧ 1`…`9`           | Move window to workspace and follow                                   |
| `⌘⇧⌥ 1`…`9`          | Move window there without following                                   |
| `` ⌘ ` `` / `⌘ S`    | Toggle scratchpad (workspace 0)                                       |
| `` ⌘⇧ ` `` / `⌘⌥ S`  | Move window to scratchpad                                             |
| `⌘⇧⌥ ←↓↑→`           | Move whole workspace to another monitor                               |
| `⌥ T`                | Toggle tiled / floating                                               |
| `⌘ O`                | Pop window out — floats it and it follows you across workspaces       |
| `⌘ J`                | Toggle window position — this workspace's split, columns ↔ rows       |
| `⌘ G`                | Toggle grouping (accordion) — press again to disassemble              |
| `⌘⌥ Tab` / `⌘⌥⇧ Tab` | Cycle within group                                                    |
| `⌘⌃ ← →`             | Move between grouped windows                                          |
| `⌘⌥ 1`…`9`           | Jump straight to the *n*th window                                     |
| `⌥ 1`…`9`            | Select browser tab — tmux window everywhere else                      |
| `⌘⌥ ←↓↑→`            | Move a window into the group in that direction                        |
| `⌘⌥ G`               | Move the focused window back out of its group                         |
| `⌘ -` / `⌘ =`        | Shrink / expand width                                                 |
| `⌘⇧ -` / `⌘⇧ =`      | Shrink / expand height                                                |
| `⌘⌥ -` / `⌘⌥ =`      | Small-step resize                                                     |
| `⌘⌃ -` / `⌘⌃ =`      | Big-step resize                                                       |
| `⌃⌥ Delete`          | Close all windows but current                                         |
| `⌥⇧ ;`               | Service mode (`esc` reload, `r` flatten, `f` float, `⌫` close others) |

Workspaces default to **tiles**, and new windows spiral (dwindle): the second window opens to
the right of the first, the third below the second, the fourth to the right of the third, and
so on.

```
┌──────────┬─────────┐
│          │    2    │
│    1     ├────┬────┤
│          │ 3  │ 4  │
└──────────┴────┴────┘
```

New windows open **full screen, edge to edge** (`fullscreen --no-outer-gaps`) rather than
appearing as a tile you then have to enlarge. The tile is still allotted underneath — only the
drawn frame covers the workspace — and AeroSpace drops the focused window out of full screen
when the next one is created, so it is always the newest window filling the screen. There is no
full-screen keybinding: `⌘F`, `⌘⌥F` and `⌘⌃F` belong to the app (Find, and friends).

`⌘J` flips the workspace's top-level split: two windows go from side by side to stacked and
back. It targets the workspace root, so nested dwindle splits keep their own orientation —
in the tree above, `⌘J` puts 1 on top of the 2/3/4 block without disturbing that block.

There is no separate layout toggle: `⌘G` already flips a workspace between dwindle and accordion
(one full-screen window, the rest collapsed to slivers at the edges), which is the nearest thing
macOS has to Omarchy's scrolling layout. The choice is per workspace, so workspace 1 can stay
dwindle while workspace 2 is accordion. If a tree gets tangled, service mode `⌥⇧;` then `r`
flattens it.

Focus is arrow-based, as in Omarchy. There is no `⌘hjkl` alias because `⌘J` is
Omarchy's window-position toggle. This takes `⌘←` / `⌘→` from the browser;
`macos-app-shortcuts.sh` puts Back and Forward on `⌥←` / `⌥→` — see
[Back and Forward](#back-and-forward).

### Grouping

AeroSpace has no window groups, so an **accordion container** stands in for one: `⌘G` collapses
the focused container into a stack of slivers with one window open, and `⌘G` again spreads it back
out. As in Omarchy, a window you open while focus is inside a group joins that group instead of
splitting off on its own.

`⌘⌥1`…`9` jump straight to the *n*th window. The index is a depth-first walk of the workspace —
top to bottom, left to right — which is the order the group lays its windows out in.

`⌘⌥←↓↑→` pulls the neighbour in that direction into a shared container with the focused window —
tiled, so follow it with `⌘G` if you want them stacked as a group. `⌘⌥G` is the inverse and pushes
the focused window back out to the surrounding container; it works out which way to go from the
group's own orientation, so there is nothing to aim.

### Popping a window out

`⌘O` pops the focused window out of the tiling tree: it floats, and it follows you onto every
workspace you switch to — good for a video player, a timer, or a terminal running an agent. `⌘O`
again drops it back into the tiling tree where you are.

Two differences from Omarchy, both deliberate: only **one** window can be pinned at a time
(pinning a second releases the first), and the window is moved just after the workspace switch
rather than being drawn there already, so it flicks into place. AeroSpace has no sticky windows
([issue #2](https://github.com/nikitabobko/AeroSpace/issues/2)); `modules/aerospace/bin/aerospace-pin.sh` fakes
one from the `exec-on-workspace-change` callback.

## Workspaces

Workspaces are free-form: **a window opens on whatever workspace is focused**, whether you
launched it with a hotkey, from the Dock or from Spotlight. Nothing is auto-assigned — press
`⌘⇧1`…`9` to move a window somewhere else, or `⌘⇧⌥1`…`9` to send it there without following.
All nine are bound, 3, 4 and 5 included — which costs the macOS screenshot hotkeys, see
[What ⌘ costs](#what--costs).

Workspace 0 is the scratchpad. Omarchy binds it twice and so does this: `` ⌘` `` or `⌘S` drops
down onto it and back, `` ⌘⇧` `` or `⌘⌥S` sends a window there. All ten workspaces are pinned to
the main monitor — see `[workspace-to-monitor-force-assignment]` in
`modules/aerospace/.config/aerospace/aerospace.toml`.

## Launching apps

| Keys            | App                                       |
| --------------- | ----------------------------------------- |
| `⌘⌥ ⏎`          | Ghostty + tmux (`main` session)           |
| `⌘⌃ ⏎`          | herdr — see [herdr](#herdr)               |
| `⌘⌃ K`          | herdr's keybindings                       |
| `⌘⇧ ⏎`          | Chrome                                    |
| `⌘⇧⌥ B`         | Chrome (incognito)                        |
| `⌘⇧ N`          | nvim — see [Neovim](#neovim)              |
| `⌘⇧ D`          | lazydocker                                |
| `⌘⌃ T`          | btop                                      |
| `⌥ G`           | Discord                                   |
| `⌘⇧ A`          | ChatGPT                                   |
| `⌘⇧ C`          | Google Calendar — web app                 |
| `⌘⇧ S`          | Google Maps — web app                     |
| `⌘⇧ F`          | Finder                                    |
| `⌘⇧ E`          | Mail                                      |
| `⌘⇧ Y` / `⌘⇧ X` | YouTube / X                               |
| `⌘⌃ S`          | LocalSend — share menu                    |

`⌥G` sits on `⌥`+letter rather than `⌘⇧`+letter, because every `⌘⇧` combination shadows a menu
command in the focused app — and Omarchy has no Discord key to match anyway, so nothing is given
up by moving it. `⌥` is otherwise free: tmux binds only `⌥`+digit, `⌥`+arrow, `⌥⏎` and `⌥⎋`; zsh
runs vi mode; nvim has no `⌥` maps. One cost: `⌥G` no longer types `©`.

lazydocker used to sit beside it on `⌥D`, and has moved to Omarchy's own `⌘⇧D` — an ordinary
Ghostty window, like every other launcher in the table. The menu commands that shadows come back
the same way every other displaced `⌘` binding's do, through `macos-app-shortcuts.sh` — see
[What ⌘ costs](#what--costs). `⌥D` types `∂` again.

`⌘⇧N` is the exception, kept on `⌘⇧` to match Omarchy's `Super+Shift+N`. It takes Chrome's
New Incognito Window — already moved to `⌘⇧⌥B` — and Finder's New Folder, which is given up;
use File ▸ New Folder.

`⌘⇧A`, `⌘⇧S` and `⌘⇧C` are Omarchy's ChatGPT, Google Maps and Google Calendar keys. ChatGPT is the
native app; Maps and Calendar are **Chrome web apps** — install a page as one from Chrome ▸ Cast,
save and share ▸ Install page as app, and it gets its own `~/Applications/Chrome Apps` bundle that
`open -a "Google Maps"` finds by name. What they cost is in [What ⌘ costs](#what--costs).

Gemini has no launcher; `⌥A` and `⌥C` are free if you want one.

### btop and the herdr keybindings

`⌘⌃T` and `⌘⌃K` open ordinary windows, like every other launcher in the table. **Omarchy floats
and centres them** — `omarchy-launch-tui` runs the TUI in a terminal under a dedicated app-id
(`org.omarchy.btop`), and the `floating-window` rule in `default/hypr/apps/system.lua` gives it
float, center and 875×600 — and that does not port:

- AeroSpace can float a window but has no command to place or resize one.
- Its catch-all `on-window-detected` rule tiles and fullscreens a new window before Ghostty has set
  the title the float rule matches on, so that rule wins only about half the time. Afterwards the
  requested geometry is gone: `fullscreen off` restores the *tile* frame rather than the original,
  which left btop 22 rows tall, refusing to draw because the terminal was too small.
- Ghostty ignores the `CSI 8 t` resize escape and will not report its position, so there is no
  fixing it from inside the window either. It does honour `window-width` / `window-height` from a
  config file, but only until AeroSpace resizes it.

A `tmux display-popup` is centred by definition and sizes correctly, being drawn inside the
terminal rather than beside it — but it lives *inside* its host window, so `⌘W` there closes that
window and takes the tmux session with it. Not worth the trade for a system monitor.

`⌘⌃K` still goes through a config file (`modules/ghostty/.config/ghostty/herdr-keys.conf`) rather
than `ghostty -e`, because `-e` makes Ghostty ask "Allow Ghostty to execute …?" every time.

### Sharing files

`⌘⌃S` is Omarchy's share menu, drawn with `fzf` instead of walker — see
`modules/aerospace/bin/localsend-share.sh`. Type to filter, `⏎` picks, `⎋` closes without doing
anything.

| Entry       | What it does                                                          |
| ----------- | --------------------------------------------------------------------- |
| `Clipboard` | Writes the pasteboard to a temp file — text as `.txt`, otherwise an image as `.png` — and sends that |
| `File`      | macOS file picker, multiple selection allowed                          |
| `Folder`    | macOS folder picker                                                    |
| `Receive`   | Just brings LocalSend forward so it can accept an incoming transfer    |

Paths reach LocalSend through `open -a LocalSend <paths>`: the app declares
`CFBundleDocumentTypes` for *Any File*, so macOS delivers them as an open-documents event and they
land staged on its Send tab.

Its command, title and 44×12 size are in `modules/ghostty/.config/ghostty/localsend-share.conf`,
and it floats through the `on-window-detected` rule in `aerospace.toml` that matches that title.
Ghostty sets the title just after the window appears, so that rule races the catch-all which
fullscreens every new window; `localsend-share.sh` runs `aerospace fullscreen off` +
`layout floating` from the inside to settle it.

One trap when editing that config: it must not `config-file` the main config to inherit it.
Includes are applied *after* the including file's own keys, so `title = ""` would win and the
AeroSpace rule would lose the title it matches on.

**LocalSend needs Local Network permission**, or it discovers no peers and the menu appears to do
nothing. Launch it once and approve the prompt; check it later under System Settings ▸ Privacy &
Security ▸ Local Network. This is the macOS counterpart of Omarchy's `ufw` rule for port 53317.

## Screen capture

`⌘⇧3/4/5` now move windows to workspaces 3, 4 and 5, so macOS's capture hotkeys are gone.
Open **Screenshot.app** instead (Spotlight → "Screenshot", or Launchpad ▸ Other) — it offers
the same whole-screen, region, window and screen-recording captures from its toolbar.

`⌘⌃⇧3` and `⌘⌃⇧4` (capture straight to the clipboard) still work: AeroSpace does not bind
`⌘⌃⇧`.

## Back and Forward

`⌥←` and `⌥→` are Back and Forward, because AeroSpace's focus keys take `⌘←` / `⌘→`.
`modules/aerospace/bin/macos-app-shortcuts.sh` sets this the same way it restores Save and Open: it rebinds the
**Back** and **Forward** menu items via `NSUserKeyEquivalents`, for every app in its list that has
them (browsers, Finder, Preview, Mail, Xcode, VS Code). Apps without those menu items ignore it.

Arrow keys in `NSUserKeyEquivalents` are the AppKit function-key constants — `U+F702` and `U+F703`
— not the `←` `→` glyphs. The script handles that; it matters only if you add bindings by hand.

One cost: a menu key equivalent is matched before the key reaches a text field, so **`⌥←` / `⌥→`
no longer move the caret a word at a time inside these apps** — including a browser text box, where
they now navigate away from the page. If that trade is not worth it, drop the `Back` and `Forward`
lines from `BINDINGS` in the script and re-run it with `--reset`, then apply.

## Copy URL

`⌥⇧L` copies the URL of the page in front of you, as in Omarchy. It exists for **web apps**: a
`⌘⇧C` Google Calendar window has no address bar, so there is no `⌘L` to copy out of.

AeroSpace's grab is global, so the binding runs `modules/aerospace/bin/copy-url.sh` from every app
and the script decides whether to act. It asks AeroSpace itself which app owns the focused window
(`aerospace list-windows --focused`) — the window manager already knows, so no Accessibility grant
is needed, and `lsappinfo` is no help because it reports AeroSpace as the front application. Unless
that bundle id is Chrome, Brave or a `com.google.Chrome.app.*` web app, the script exits without
touching the clipboard. Only then does it ask Chrome for `URL of active tab of front window` and
pipe it to `pbcopy`.

A web app window is an ordinary Chrome window — only its frame is drawn by the app shim — so it is
Chrome's `front window` while the shim is frontmost, and one AppleScript line covers both cases.
macOS asks once to let AeroSpace control Chrome; say yes or nothing is ever copied.

One cost: `⌥⇧L` no longer types `Ò`.

## Browser tabs

`⌥1`…`⌥8` select that tab and `⌥9` selects the last one, exactly as `⌘1`…`⌘9` used to before
AeroSpace took the ⌘ digits for workspaces.

This one needs Karabiner-Elements, and it is the only binding here that does. The menu-rebind
trick used everywhere else cannot help: Chrome's Tab menu offers only *Select Next/Previous Tab*
plus the open tabs by page title, so there is no stable menu item to bind. Nor can `⌥N` simply be
remapped to `⌘N` — AeroSpace's grab is global and swallows a synthesised `⌘N` before the browser
sees it. So Karabiner matches `⌥1`…`⌥9` **only while a browser is frontmost** and runs
`modules/karabiner/bin/browser-tab.sh`, which drives the tab via AppleScript in about 100 ms.

Because the rule is scoped to Chrome, Brave and Safari, `⌥1`…`⌥9` still reach tmux everywhere
else — see [tmux](#tmux). Add browsers by bundle ID in
`modules/karabiner/.config/karabiner/karabiner.json` and
`modules/karabiner/bin/browser-tab.sh`.

## System panels

| Keys    | Panel                |
| ------- | -------------------- |
| `⌘⌃ A`  | Sound                |
| `⌘⌃ B`  | Bluetooth            |
| `⌘⌃ W`  | Network              |
| `⌘⌃ D`  | Displays             |
| `⌘⌃ P`  | Battery              |
| `⌘⌃ Q`  | Calculator           |
| `⌘⌃ L`  | Lock (display sleep) |

`⌘⌃S` is not a panel — it is the LocalSend share menu, in
[Sharing files](#sharing-files). Neither is `⌘⌃T`: Omarchy labels that one "Activity (btop)", so
it is btop, not Activity Monitor.app. The GUI app has no key at all
now — open it from Spotlight on the rare occasion you want it (force-quitting something, or a
`kill` target you cannot find).

## tmux

Prefix is `⌃B`. Omarchy documents it as "Ctrl+Space or Ctrl+B"; `⌃Space` is unavailable here
because it is nvim's cmp completion trigger.

| Keys                                 | Action                                                    |
| ------------------------------------ | --------------------------------------------------------- |
| `prefix v` / `prefix h`              | Split vertical (side by side) / horizontal (stacked)      |
| `prefix x` / `prefix z`              | Kill pane / zoom pane                                     |
| `⌥ ⏎` / `⌥⇧ ⏎`                       | Split below / beside (no prefix)                          |
| `⌥ Esc`                              | Kill pane (no prefix)                                     |
| `⌃⌥ ←↓↑→`                            | Move between panes                                        |
| `⌃⌥⇧ ←↓↑→`                           | Resize pane                                               |
| `prefix c` / `prefix k` / `prefix r` | New / kill / rename window                                |
| `⌥ 1`…`9`                            | Go to window (selects a tab in browsers)                  |
| `⌥ ← →`                              | Previous / next window                                    |
| `⌥⇧ ← →`                             | Move window left / right                                  |
| `prefix C` / `K` / `R` / `N` / `P`   | New / kill / rename / next / previous session             |
| `⌥ ↑ ↓`                              | Previous / next session                                   |
| `prefix s` / `d` / `[`               | Sessions / detach / copy mode                             |
| `prefix q`                           | Reload config (Omarchy puts rename-window on `r`)         |
| `prefix ?` / `prefix :`              | Show bindings / command prompt                            |
| `prefix E` / `O` / `V`               | Scratch note / todo / nvim pane (moved from lowercase)    |

`⌥⇧⏎` needs the terminal to distinguish Shift+Enter from Enter, which plain xterm encoding
cannot. tmux asks for it with `extended-keys on`, which Ghostty answers by default.

## Tmux layouts

Omarchy's layout functions, ported to zsh in `modules/zsh/.zshrc`, plus `tdh`. All five must be run
**inside** a tmux session.

| Command                | Layout                                                              |
| ---------------------- | ------------------------------------------------------------------- |
| `tdl <ai> [<ai2>]`     | Editor left, AI right (30%), terminal below (15%)                   |
| `tdh <ai> [<ai2>]`     | The same, with `hunk diff --watch` on the left instead of an editor |
| `tds`                  | Four quadrants: editor, `hunk diff --watch`, terminal, opencode     |
| `tdlm <ai> [<ai2>]`    | One `tdl` window per subdirectory — switch with `⌥ 1`…`9`             |
| `tsl <count> <cmd>`    | `count` tiled panes, all running `cmd`                              |

`tdl` renames the window after the current directory and opens `$EDITOR` (nvim) on the left.

`tdh` takes the same arguments and builds the same three panes, but the left one runs
[hunk](https://hunk.dev) `--watch` — the layout for when the agent does the writing and you only
read the diff. It leaves the AI pane focused rather than the left one, for the same reason.

`tds` takes no arguments. Its diff pane runs [hunk](https://hunk.dev), a terminal diff viewer, with
`--watch` so it re-renders as the agent edits files.

| Alias  | Runs                                    |
| ------ | --------------------------------------- |
| `c`    | opencode                                |
| `cx`   | claude (auto mode)                      |
| `cy`   | codex                                   |
| `ic`   | `tdl c` — editor + opencode              |
| `ix`   | `tdl cx` — editor + claude               |
| `icx`  | `tdl c cx` — editor + opencode + claude  |
| `t`    | Attach to tmux, or start session `main` |

## herdr

`⌘⌃⏎` starts [herdr](https://herdr.dev), or reattaches to the session you already have. It is a
second multiplexer alongside tmux — workspaces, tabs and panes in a persistent session you can
detach from and come back to — built around keeping coding agents running rather than shells.
Ghostty opens it as an ordinary full window, exactly as `⌘⌥⏎` does tmux.

**The prefix is `⌃B`**, herdr's own default and the same as tmux's here. Omarchy remaps it to
`⌃Space`; that key is unavailable on this machine because it is nvim's cmp completion trigger —
the same reason the [tmux](#tmux) prefix is not `⌃Space` either. Sharing a prefix with tmux costs
nothing as long as you do not nest one inside the other, which there is no reason to do: they are
alternatives, not layers.

| Keys       | Action                                   |
| ---------- | ---------------------------------------- |
| `⌘⌃ ⏎`     | Start herdr, or reattach                 |
| `⌘⌃ K`     | Browse the bindings                      |
| `prefix ?` | The same list, in-app                    |
| `prefix q` | Detach                                   |
| `prefix w` | Workspace picker                         |
| `prefix c` | New tab                                  |

`⌘⌃K` exists because `prefix ?` only works when herdr is the window in front of you. Omarchy draws
its version with a Hyprland menu; herdr itself exposes no such command, so
`modules/aerospace/bin/herdr-keys.sh` is a port of Omarchy's
`bin/omarchy-menu-herdr-keybindings`, with `fzf` standing in for walker. It reads the action list
and its defaults out of `herdr --default-config`, where each one appears as a commented
`# action = "binding"` line, then lets `~/.config/herdr/config.toml` override them, and renders
`PREFIX + N → Next tab`. Type to filter, `⎋` closes.

That config file is **not** stowed and not in this repo — herdr writes it itself, and everything
here works off the defaults. `herdr server reload-config` picks up an edit without a restart, and
`herdr config reset-keys` backs the file up and restores the default bindings.

### herdr layouts

The same five layouts, against herdr instead of tmux. Run them **inside** herdr — they key off
`$HERDR_PANE_ID`, the way the tmux ones key off `$TMUX`.

| Command                | Layout                                                          |
| ---------------------- | --------------------------------------------------------------- |
| `hdl <ai> [<ai2>]`     | Editor left, AI right (30%), terminal below (15%)               |
| `hdh <ai> [<ai2>]`     | The same, with `hunk diff --watch` instead of an editor         |
| `hds`                  | Four quadrants: editor, `hunk diff --watch`, terminal, opencode |
| `hdlm <ai> [<ai2>]`    | One `hdl` tab per subdirectory, and renames the workspace       |
| `hsl <count> <cmd>`    | `count` panes in a grid, all running `cmd`                      |

Two differences from the tmux versions, both from herdr's CLI rather than choice. Commands are
handed to `herdr pane run` instead of typed in as keystrokes, and pane ids come back as JSON, so
these need `jq`. `hsl` also builds a real `ceil(sqrt(n))` grid itself, where `tsl` just splits and
lets `select-layout tiled` sort it out.

## Git worktrees

| Command       | Action                                                            |
| ------------- | ----------------------------------------------------------------- |
| `ga <branch>` | Worktree + branch at `../<repo>--<branch>`, then `cd` into it     |
| `gd`          | Remove the worktree and its branch, from inside it (asks first)   |

The `--` in the directory name is the contract between the two: `ga` writes it, `gd` splits on the
first one to recover the repo and branch, and does nothing at all in a directory that has none. So
renaming a worktree directory breaks `gd`. `gd` confirms with `gum` before deleting anything.

These take the `ga`/`gd` names back from oh-my-zsh's git plugin, where they are `git add` and
`git diff` — hence the `unalias ga gd` above the definitions in `.zshrc`. The aliases would
otherwise also be expanded in the `ga() {` line itself, which is a parse error, not a shadowing.

## Terminal

Both terminals send Option as Meta so the tmux Alt layer works.

| Keys            | Action                          |
| --------------- | ------------------------------- |
| `⌃⇧ T`          | New tab                         |
| `⌃⇧ ← →`        | Move tab                        |
| `⌃⇧ E` / `⌃⇧ O` | Split down / right _(Ghostty)_  |
| `⌃⌥ ←↓↑→`       | Move between splits _(Ghostty)_ |
| `⌘⌃⇧ ←↓↑→`      | Resize split _(Ghostty)_        |

`⌥1-9` is deliberately unbound in Ghostty so those keys reach tmux.

## Neovim

`⌘⇧N` opens nvim in a fresh Ghostty window — the row in [Launching apps](#launching-apps). It names
`/opt/homebrew/bin/nvim` outright rather than `$EDITOR`, because AeroSpace's `exec-and-forget` runs
under `/bin/sh`, which never sources `.zshrc` and so would find `$EDITOR` empty.

Usually it is easier to start from a terminal you are already in. `cd` to the directory you want to
work in and type `n`, which opens nvim on the current directory. `n myfile.txt` opens a single file.

| Command           | Opens                         |
| ----------------- | ----------------------------- |
| `n`               | The current directory         |
| `n myfile.txt`    | One file                      |
| `sudoedit FILE`   | A root-owned file (see below) |

### Editing root-owned files

As on Omarchy, `sudoedit`:

```shell
sudoedit /etc/hosts
```

Your whole config comes with it, plugins and LSP included. sudo copies the file somewhere you own,
runs the editor on the copy as *you*, then copies it back; from `man sudo`, "the editor is run with
the invoking user's environment unmodified". It picks nvim from `EDITOR`, exported in `.zshrc`.

**`sudo -e` is not a substitute, despite the man page implying it is.** sudo chooses its mode from
the name it was invoked under, and `sudoers(5)` spells out what that costs you:

> Unless invoked as sudoedit, sudo does not preserve the SUDO_EDITOR, VISUAL or EDITOR environment
> variables unless they are present in the env_keep list or the env_reset option is disabled.

So `sudo -e` has `EDITOR` stripped by `env_reset`, falls back to the sudoers `editor` list, and
drops you in `/usr/bin/vi` with no config at all.

macOS ships no `sudoedit` binary — only `/usr/bin/sudo` — so `modules/nvim/install.sh` creates the
link Linux ships by default:

```shell
~/.local/bin/sudoedit -> /usr/bin/sudo
```

`make install` runs that hook. It is not stowed: stow aborts on an absolute symlink inside a
package, and a relative one would need a fixed count of `../` to climb out of the repo. It has to
be a real link, too — sudo resolves its own executable path, so faking `argv[0]` with
`exec -a sudoedit` leaves it in ordinary sudo mode.

Do not reach for `sudo nvim` instead. That runs as root with root's empty environment, so you get a
bare editor and a scattering of root-owned files in `~/.local`.

---

## What ⌘ costs

AeroSpace's ⌘ bindings are global, so the macOS commands they displace are re-bound onto plain
`⌃` — the Linux convention. Run once per machine:

```sh
cd ~/dotfiles && make macos-shortcuts     # make macos-shortcuts-reset to undo
```

| Was                 | Now       |
| ------------------- | --------- |
| `⌘G` Find Next      | `⌃G`      |
| `⌘⇧G` Find Previous | `⌃⇧G`     |
| `⌘O` Open           | `⌃O`      |
| `⌘S` Save           | `⌃S`      |
| `⌘P` Print          | `⌃P`      |
| `⌘J` Downloads      | `⌃J`      |
| `⌘⇧A` Search Tabs   | `⌃⇧A`     |
| `⌘⇧D` Bookmark All Tabs, Finder's Go ▸ Desktop | `⌃⇧D` |
| `⌘-` `⌘=` Zoom      | `⌃-` `⌃=` |

These are per-app menu rebinds, never global — `⌃F` stays zsh `autosuggest-accept`, and `⌃L` `⌃J`
`⌃K` reach whatever is running in the terminal (`⌃L` clear, `⌃J` a newline in Claude Code).

`⌘⇧G` is in the table for the opposite reason to the rest: AeroSpace does not take it, but every
AppKit app binds it to Find Previous, so an app that wants it as its own global hotkey refuses it
(Gemini's Speak to Window, for one). Moving Find Previous to `⌃⇧G` frees it.

`⌘F`, `⌘T` and `⌘L` are **not** in that table: nothing is bound to `⌘F` any more, the
tiled/floating toggle sits on `⌥T` and there is no layout toggle at all, so Find, New Tab and
Open Location work natively.

**`⌘S` no longer saves.** It is the scratchpad toggle, and Save falls back to `⌃S` only in the
apps listed in `modules/aerospace/bin/macos-app-shortcuts.sh`. Anywhere else, Save is reachable from File ▸ Save
and nowhere else — add the app's bundle ID to that list and re-run `make macos-shortcuts`.

`⌘1`…`⌘9` no longer select browser tabs — they are the workspace switches. **`⌥1`…`⌥9` do it
instead**, via Karabiner; see [Browser tabs](#browser-tabs). `⌃Tab` / `⌃⇧Tab` still cycle.

**`⌘Q` still quits, natively.** Omarchy's `killactive` is deliberately left unbound: taking
`⌘Q` for close-one-window would leave macOS with no quit hotkey at all. Close a single window
with `⌘W`, or `⌃⌥⌫` to close every window but the focused one.

**`⌘⇧A` `⌘⇧C` `⌘⇧D` `⌘⇧S` are launchers** — ChatGPT, Google Calendar, lazydocker and Google Maps.
`⌘⇧D` costs Chrome's Bookmark All Tabs and Finder's Go ▸ Desktop, both back on `⌃⇧D` in the table
above; in any other app whose `⌘⇧D` you miss, add its menu item's exact title to `BINDINGS` in
`macos-app-shortcuts.sh`. `⌘⇧A` costs Chrome's
Search Tabs, which the table above puts back on `⌃⇧A` (with ⇧, because plain `⌃A` is
beginning-of-line in every text field). `⌘⇧S` costs Save As in the apps that bind it — plain Save
is already on `⌃S`, and macOS's own Save As is `⌥⇧⌘S`. `⌘⇧C` costs nothing here: Inspect Element is
`⌥⌘C` on macOS, not `⌘⇧C`.

**`⌘⌃S` costs nothing.** macOS binds no system command to it and the `⌘⌃` family here is
otherwise system panels, so the share menu displaces nothing. It is not the scratchpad — that is
`⌘S` / `⌘⌥S`.

**`⌘⌃T` no longer opens Activity Monitor** — it is btop now.

**`⌘⇧3` `⌘⇧4` `⌘⇧5` no longer capture the screen** — they move windows to workspaces 3, 4 and 5.
See [Screen capture](#screen-capture).

`⌘W` `⌘C` `⌘V` `⌘X` `⌘Space` are left alone — macOS already does with them what Omarchy does, so
they need no porting.

## Not available on macOS

AeroSpace has no equivalent, and nothing here fakes one:

- `Super+P` pseudo style
- `Super+Ctrl+Z` zoom, `Super+/` scaling steps
- `Super+Home` width save/restore
- `Super+Scroll` workspace scrolling, `Super+Mouse` drag/resize
- Omarchy's Notifications, Style, Toggles, Reminders and Notices sections — these are
  Hyprland-ecosystem specific (mako, waybar, hyprsunset)

Two more are approximated rather than matched. Accordion (`⌘G`) stands in for the scrolling
layout, but AeroSpace keeps no per-workspace layout state, so unlike Omarchy the choice is lost
when AeroSpace restarts. `⌘O` fakes a sticky window and can pin only one at a time — see
[Popping a window out](#popping-a-window-out).
