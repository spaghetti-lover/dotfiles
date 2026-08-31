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
| `` ⌘ ` ``            | Toggle scratchpad (workspace 0)                                       |
| `` ⌘⇧ ` ``           | Move window to scratchpad                                             |
| `⌘⇧⌥ ←↓↑→`           | Move whole workspace to another monitor                               |
| `⌘ T`                | Toggle tiled / floating                                               |
| `⌘ J`                | Toggle window position                                                |
| `⌘ L`                | Toggle layout (accordion / tiles) — flips this workspace to a split   |
| `⌘ F`                | Full screen                                                           |
| `⌘⌥ F`               | Full width                                                            |
| `⌘⌃ F`               | macOS native full screen                                              |
| `⌘ G`                | Toggle grouping (accordion)                                           |
| `⌘⌥ Tab` / `⌘⌥⇧ Tab` | Cycle within group                                                    |
| `⌘⌃ ← →`             | Move between windows                                                  |
| `⌘⌥ ←↓↑→`            | Move window into a group                                              |
| `⌘ -` / `⌘ =`        | Shrink / expand width                                                 |
| `⌘⇧ -` / `⌘⇧ =`      | Shrink / expand height                                                |
| `⌘⌥ -` / `⌘⌥ =`      | Small-step resize                                                     |
| `⌘⌃ -` / `⌘⌃ =`      | Big-step resize                                                       |
| `⌃⌥ Delete`          | Close all windows but current                                         |
| `⌥⇧ ;`               | Service mode (`esc` reload, `r` flatten, `f` float, `⌫` close others) |

Workspaces default to the **accordion** layout: a new window takes the full screen and the
others collapse to slivers at the edges, rather than splitting the screen side by side.
`⌘L` flips the current workspace to a tiled split and back; the default only applies to a
workspace's root container when it is first created.

Focus is arrow-based, as in Omarchy. There are no `⌘hjkl` aliases because `⌘J` and `⌘L` are
Omarchy's window-position and layout toggles.

## Workspaces

|           |         |           |               |              |
| --------- | ------- | --------- | ------------- | ------------ |
| 1 Coding  | 2 Notes | 3 Browser | 4 Work / chat | 5 Files      |
| 6 Reading | 7 Media | 8 Tools   | 9 VM          | 0 Scratchpad |

Apps auto-assign on launch — see `[[on-window-detected]]` in
`aerospace/.config/aerospace/aerospace.toml`.

## Launching apps

| Keys            | App                             |
| --------------- | ------------------------------- |
| `⌘ ⏎`           | WezTerm                         |
| `⌘⌥ ⏎`          | WezTerm + tmux (`main` session) |
| `⌘⇧ ⏎`          | Brave                           |
| `⌘⇧⌥ B`         | Brave (incognito)               |
| `⌘⇧ N`          | nvim                            |
| `⌘⇧ D`          | lazydocker                      |
| `⌘⇧ F`          | Finder                          |
| `⌘⇧ G`          | Discord                         |
| `⌘⇧ A`          | Gemini                          |
| `⌘⇧ C` / `⌘⇧ E` | Calendar / Mail                 |
| `⌘⇧ Y` / `⌘⇧ X` | YouTube / X                     |

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
| `⌘⌃⌥ D` | Calendar             |

## tmux

Prefix is `⌃A`. Omarchy documents the prefix as "Ctrl+Space or Ctrl+B"; `⌃Space` is unavailable
here because it is nvim's cmp completion trigger.

| Keys                                 | Action                                                    |
| ------------------------------------ | --------------------------------------------------------- |
| `prefix v` / `prefix h`              | Split vertical (side by side) / horizontal (stacked)      |
| `prefix x` / `prefix z`              | Kill pane / zoom pane                                     |
| `⌥ ⏎` / `⌥⇧ ⏎`                       | Split below / beside (no prefix)                          |
| `⌥ Esc`                              | Kill pane (no prefix)                                     |
| `⌃⌥ ←↓↑→`                            | Move between panes                                        |
| `⌃⌥⇧ ←↓↑→`                           | Resize pane                                               |
| `⌃ hjkl`                             | Move between panes _and_ nvim splits (vim-tmux-navigator) |
| `prefix c` / `prefix k` / `prefix r` | New / kill / rename window                                |
| `⌥ 1`…`9`                            | Go to window                                              |
| `⌥ ← →`                              | Previous / next window                                    |
| `⌥⇧ ← →`                             | Move window left / right                                  |
| `prefix C` / `K` / `R` / `N` / `P`   | New / kill / rename / next / previous session             |
| `⌥ ↑ ↓`                              | Previous / next session                                   |
| `prefix s` / `d` / `[`               | Sessions / detach / copy mode                             |
| `prefix q`                           | Reload config (Omarchy puts rename-window on `r`)         |
| `prefix ?` / `prefix :`              | Show bindings / command prompt                            |
| `prefix E` / `O` / `V`               | Scratch note / todo / nvim pane (moved from lowercase)    |

## Terminal

Both terminals send Option as Meta so the tmux Alt layer works.

| Keys            | Action                            |
| --------------- | --------------------------------- |
| `⌃⇧ T`          | New tab (⌘T belongs to AeroSpace) |
| `⌃⇧ ← →`        | Move tab                          |
| `⌃⇧ E` / `⌃⇧ O` | Split down / right _(Ghostty)_    |
| `⌃⌥ ←↓↑→`       | Move between splits _(Ghostty)_   |
| `⌘⌃⇧ ←↓↑→`      | Resize split _(Ghostty)_          |

`⌥1-9` is deliberately unbound in Ghostty so those keys reach tmux.

---

## What ⌘ costs

AeroSpace's ⌘ bindings are global, so the macOS commands they displace are re-bound onto plain
`⌃` — the Linux convention. Run once per machine:

```sh
cd others && make macos-shortcuts     # make macos-shortcuts-reset to undo
```

| Was                | Now                              |
| ------------------ | -------------------------------- |
| `⌘F` Find          | `⌃F`                             |
| `⌘G` Find Next     | `⌃G`                             |
| `⌘T` New Tab       | `⌃T`                             |
| `⌘L` Open Location | `⌃L` (F6 also works in browsers) |
| `⌘O` Open          | `⌃O`                             |
| `⌘P` Print         | `⌃P`                             |
| `⌘J` Downloads     | `⌃J`                             |
| `⌘-` `⌘=` Zoom     | `⌃-` `⌃=`                        |

These are per-app menu rebinds, never global — `⌃F` stays zsh `autosuggest-accept` and `⌃L` `⌃J`
`⌃K` stay vim-tmux-navigator inside terminals.

**Not recoverable:** `⌘1`…`⌘9` for browser tab selection — browsers expose no menu item for
"switch to tab N". Use `⌃Tab` / `⌃⇧Tab`, which cycle tabs natively.

`⌘W` `⌘Q` `⌘C` `⌘V` `⌘X` `⌘S` `⌘Space` are left alone — macOS already does with them what Omarchy
does, so they need no porting.

## Not available on macOS

AeroSpace has no equivalent, and nothing here fakes one:

- `Super+O` sticky floating overlay
- Scrolling layout, `Super+P` pseudo style
- `Super+Ctrl+Z` zoom, `Super+/` scaling steps
- `Super+Home` width save/restore
- `Super+Scroll` workspace scrolling, `Super+Mouse` drag/resize
- Omarchy's Notifications, Style, Toggles, Reminders and Notices sections — these are
  Hyprland-ecosystem specific (mako, waybar, hyprsunset)
