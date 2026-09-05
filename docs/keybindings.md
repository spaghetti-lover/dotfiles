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

| Keys            | App                             |
| --------------- | ------------------------------- |
| `⌘⌥ ⏎`          | Ghostty + tmux (`main` session) |
| `⌘⇧ ⏎`          | Chrome                          |
| `⌘⇧⌥ B`         | Chrome (incognito)              |
| `⌘⇧ N`          | nvim — see [Neovim](#neovim)    |
| `⌥ D`           | lazydocker                      |
| `⌥ G`           | Discord                         |
| `⌘⇧ A`          | ChatGPT                         |
| `⌘⇧ C`          | Google Calendar — web app       |
| `⌘⇧ S`          | Google Maps — web app           |
| `⌘⇧ F`          | Finder                          |
| `⌘⇧ E`          | Mail                            |
| `⌘⇧ Y` / `⌘⇧ X` | YouTube / X                     |

`⌥D` and `⌥G` sit on `⌥`+letter rather than `⌘⇧`+letter, because every `⌘⇧` combination shadows a
menu command in the focused app. `⌥` is otherwise free: tmux binds only `⌥`+digit, `⌥`+arrow, `⌥⏎`
and `⌥⎋`; zsh runs vi mode; nvim has no `⌥` maps. One cost: `⌥D` and `⌥G` no longer type `∂` `©`.

`⌘⇧N` is the exception, kept on `⌘⇧` to match Omarchy's `Super+Shift+N`. It takes Chrome's
New Incognito Window — already moved to `⌘⇧⌥B` — and Finder's New Folder, which is given up;
use File ▸ New Folder.

`⌘⇧A`, `⌘⇧S` and `⌘⇧C` are Omarchy's ChatGPT, Google Maps and Google Calendar keys. ChatGPT is the
native app; Maps and Calendar are **Chrome web apps** — install a page as one from Chrome ▸ Cast,
save and share ▸ Install page as app, and it gets its own `~/Applications/Chrome Apps` bundle that
`open -a "Google Maps"` finds by name. What they cost is in [What ⌘ costs](#what--costs).

Gemini has no launcher; `⌥A` and `⌥C` are free if you want one.

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
| `⌘⌃ T`  | Activity Monitor     |
| `⌘⌃ Q`  | Calculator           |
| `⌘⌃ L`  | Lock (display sleep) |

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
| `⌃ hjkl`                             | Move between panes (vim-tmux-navigator; stops at nvim)    |
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

Omarchy's layout functions, ported to zsh in `modules/zsh/.zshrc`. All three must be run **inside** a
tmux session.

| Command                | Layout                                                              |
| ---------------------- | ------------------------------------------------------------------- |
| `tdl <ai> [<ai2>]`     | Editor left, AI right (30%), terminal below (15%)                   |
| `tdlm <ai> [<ai2>]`    | One `tdl` window per subdirectory — switch with `⌥ 1`…`9`             |
| `tsl <count> <cmd>`    | `count` tiled panes, all running `cmd`                              |

`tdl` renames the window after the current directory and opens `$EDITOR` (nvim) on the left.

| Alias  | Runs                                    |
| ------ | --------------------------------------- |
| `c`    | opencode                                |
| `cx`   | claude (permissions bypassed)           |
| `cy`   | codex                                   |
| `ic`   | `tdl c` — editor + opencode              |
| `ix`   | `tdl cx` — editor + claude               |
| `icx`  | `tdl c cx` — editor + opencode + claude  |
| `t`    | Attach to tmux, or start session `main` |

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
cd others && make macos-shortcuts     # make macos-shortcuts-reset to undo
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
| `⌘-` `⌘=` Zoom      | `⌃-` `⌃=` |

These are per-app menu rebinds, never global — `⌃F` stays zsh `autosuggest-accept` and `⌃L` `⌃J`
`⌃K` stay vim-tmux-navigator inside terminals.

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

**`⌘⇧A` `⌘⇧C` `⌘⇧S` are launchers** — ChatGPT, Google Calendar and Google Maps. `⌘⇧A` costs Chrome's
Search Tabs, which the table above puts back on `⌃⇧A` (with ⇧, because plain `⌃A` is
beginning-of-line in every text field). `⌘⇧S` costs Save As in the apps that bind it — plain Save
is already on `⌃S`, and macOS's own Save As is `⌥⇧⌘S`. `⌘⇧C` costs nothing here: Inspect Element is
`⌥⌘C` on macOS, not `⌘⇧C`.

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
