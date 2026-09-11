# yabai

A second window manager, side by side with AeroSpace. Same Omarchy keys, a
different engine underneath. `docs/keybindings.md` remains the cheat sheet for
both; this file is the yabai-specific half.

## Why

Three things on `docs/keybindings.md`'s *Not available on macOS* list are things
AeroSpace structurally cannot do, and yabai does natively:

| | AeroSpace | yabai |
| --- | --- | --- |
| `⌘G` grouping | accordion stand-in | real stacks: `stack-index`, `stack.N`, drag-to-stack |
| `⌘O` pop-out | `aerospace-pin.sh` fakes it, one window, flicks into place | native sticky, any number, drawn in place |
| `⌘`+drag / right-drag | not available | `mouse_modifier cmd` |
| `⌘⌃F` / `⌘⌥F` | unbound | `zoom-parent` / `windowed-fullscreen` |

## Switching

```sh
make wm-yabai      # quits AeroSpace, starts yabai + skhd
make wm-aerospace  # stops yabai + skhd, starts AeroSpace
make wm-status     # which is configured, and which is actually running
```

They can never run together: both grab `cmd` combinations globally, so with both
up every `cmd` chord is a race. The choice is written to `~/.config/dotfiles/wm`
and enforced at startup -- AeroSpace has `start-at-login` and returns after a
reboot regardless, so it asks `wm.sh guard-aerospace` whether it is still wanted
and quits again if not. `yabai --stop-service` does a launchd `disable`, so the
reverse needs no guard, but `yabairc` calls `guard-yabai` anyway.

**Run `make wm-aerospace` before the first `make stow`.**

## The scripting addition

yabai injects an addition into `Dock.app` for the things the window server owns.
It needs SIP partially disabled *and* `-arm64e_preview_abi` in `boot-args`, both
of which are already set on this machine.

```sh
make yabai-sa      # (re)authorise it -- rerun after every `brew upgrade yabai`
```

The sudoers rule pins the binary's SHA-256, so an upgrade invalidates it and
`--load-sa` begins failing *silently*. `yabairc` notices and drops a breadcrumb
at `~/.cache/yabai/no-sa`; if a feature below has stopped working, look there
first.

### Status on macOS 26.6.2: unresolved

yabai's changelog names addition updates for macOS 26.2, 26.3 and 26.4. This
machine runs **26.6.2**, which is named nowhere, and `sudo -n yabai --load-sa`
returns **exit 1 with no output**. That is very likely yabai failing rather than
sudo refusing -- `sudo -n true` prints "a password is required" and this printed
nothing.

The definitive probe needs yabai actually running:

```sh
before=$(yabai -m query --spaces | jq length)
yabai -m space --create; echo "exit=$?"
yabai -m query --spaces | jq length          # must be $before + 1
yabai -m space --destroy
```

`space --create` is addition-only with no fallback path, which makes it the
clean test. **`space --focus` is not** -- it stopped needing SIP in yabai 7.1.19,
as did `window --space` in 7.1.25.

### What breaks without it

**Lost:** `space --create/--destroy/--move/--swap/--display`; `window --toggle
sticky|pip|shadow`; `--sub-layer`; `--opacity`; `--raise/--lower`;
`--scratchpad`; the `sticky`, `sub-layer`, `opacity` and `scratchpad` rule
properties.

**Survives:** `⌘1..9` and `⌘⇧1..9`, all bsp tiling, `--stack` / `--warp` /
`--swap` / `--insert` / `--ratio` / `--resize` / `--grid`, `space --layout`,
`--balance`, `--gap`, `--padding`, every signal, and the whole mouse subsystem.

**So in practice:** grouping and mouse/fullscreen are unaffected. `⌘O` degrades
to a centred float that does *not* follow you -- worse than `aerospace-pin.sh` --
and the nine spaces have to be created by hand once in Mission Control, after
which `setup-spaces.sh` still labels them and `⌘1..9` works.

## Workspaces are real macOS Spaces

The single biggest difference from AeroSpace, and the source of most of the
known gaps below.

`setup-spaces.sh` runs on every yabai start and labels the first ten spaces on
the main display `ws1..ws9` and `scratch`. **skhd binds labels, not Mission
Control indices**, because indices are global across displays and shift whenever
a space is created or destroyed anywhere -- `space --focus 3` stops meaning
workspace 3 the moment you add a space on the DELL. Labels survive that, but not
a yabai restart, which is why the script re-runs each time.

It is idempotent and never destructive: too few spaces and it creates the
difference, too many and it leaves the extras alone. Destroying a space silently
relocates its windows.

### Prerequisites

| Setting | Wanted | Check |
| --- | --- | --- |
| Displays have separate Spaces | on | `defaults read com.apple.spaces spans-displays` -- absent or `0` |
| Automatically rearrange Spaces | **off** | `defaults read com.apple.dock mru-spaces` -- must be `0` |

```sh
defaults write com.apple.dock mru-spaces -bool false && killall Dock
```

Two ordering notes: `spans-displays` needs a **log out**, not a Dock restart.
And `killall Dock` **drops the scripting addition** -- do the writes before
starting yabai, or let the `dock_did_restart` signal in `yabairc` reinject it.

## Grouping

`⌘G` toggles a real stack; `⌘⌥←↓↑→` pulls a neighbour in; `⌘⌥G` ejects;
`⌘⌥Tab` and `⌘⌥1..5` move within it. After grouping, `--insert stack` is set so
that new windows join the group -- Omarchy's "every window you start while the
group is active belongs to the group".

Two honest caveats:

- **Stacks do not survive a yabai restart.** They live in the in-memory BSP tree
  and die with the process, exactly as AeroSpace's accordion did. What yabai
  buys is *real* stacks, not *persistent* ones.
- **`⌘⌥L` is a different feature.** It flips the whole space between `bsp` and
  `stack` -- Omarchy's dwindle/scrolling toggle -- and *is* persisted, in
  `~/.local/state/yabai/layout/`. One window visible, the rest behind it.

## Known gaps

**No equivalent exists:**

- **No space-to-display pinning.** AeroSpace's
  `[workspace-to-monitor-force-assignment]` has no counterpart; macOS spaces
  belong to a display. `setup-spaces.sh` drags stray labelled spaces back to the
  main display on hot-plug, but macOS reassigns them *before* yabai reports the
  event, so there is a window in which `⌘1..9` lands on the wrong screen. This
  is the clearest regression from AeroSpace.
- **No per-display gaps or padding.** Only global and per-space, so the
  built-in-vs-DELL split in `aerospace.toml` becomes the built-in's values
  everywhere.
- **Sticky implies float.** There is no sticky-and-tiled window.
- **Nine spaces are permanently visible** in Mission Control and the three-finger
  swipe, whether or not they hold windows. Virtual workspaces never showed there.

**Not persisted:** space labels, stacks, and scratchpad assignments all die with
the process. (`yabai -m window --scratchpad recover` un-hides orphans.) Per-space
*layout* is the one thing that is, via `layout-memo.sh`.

**Deliberately not ported** -- yabai supports all of these; they are choices:

- `Super+F` plain fullscreen (`zoom-fullscreen`), so `⌘F` stays Find.
- `Super+Backspace` transparency and `Super+Shift+Backspace` gaps toggle, so
  `⌘⌫` stays Finder's Move to Trash.
- `Super+Home` window width save/restore -- `Home` is `fn+←` on the built-in
  keyboard.
- The scratchpad uses a labelled space rather than `window --scratchpad`, which
  is the closer analogue but needs the scripting addition.

**Still impossible under either manager**, as `docs/keybindings.md` records:
`Super+P` pseudo, `Super+Ctrl+Z` zoom, `Super+/` scaling, `Super+Scroll`, and the
Hyprland-ecosystem sections.

## Notes

`skhd 0.3.9` is upstream maintenance-only. [`skhd.zig`](https://github.com/jackielii/skhd.zig)
is config-compatible, so this module would port across cleanly -- but it changes
both the tap and the launchd label, so it is a separate change.
