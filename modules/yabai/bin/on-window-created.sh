#!/usr/bin/env bash
#
# Everything that happens to a new window. Driven by two signals in
# .config/yabai/yabairc, and it does one of two things:
#
#   1. A TUI in the float namespace gets Hyprland's `float + center + size` --
#      the one thing AeroSpace could not do, since it floats a window but has no
#      command to place or resize one.
#   2. Anything else opens zoomed to fill the space, which is what AeroSpace's
#      catch-all `fullscreen --no-outer-gaps` rule did: a new window arrives
#      edge to edge rather than as a tile you then have to enlarge. Its place in
#      the tree is unchanged -- only the drawn frame covers the space.
#
# Branch 2 belongs to the window_created signal alone; branch 1 is reachable
# from window_title_changed too. The reason is that the tui_float rule, which is
# what is supposed to keep these windows unmanaged, **intermittently declines a
# window it should match** -- between one launch in ten and one in two,
# depending on the run. When it declines, the window is tiled, and by the time
# this script queries it the title reads correctly, so all we can say is that
# the rule saw something different from what we see a few milliseconds later.
# Whether Ghostty had not applied the title yet or yabai's matching is flaky is
# not observable from here; either way nothing else would put the window right.
#
# Two consequences, both handled below: the script floats the window itself
# rather than trusting the rule (see the --toggle float in branch 1), and the
# size cannot be read back off the window, because the tile frame has already
# overwritten it (see the `case $title` table).
#
# Usage: on-window-created.sh <window-id> [float-width] [float-height]
#        on-window-created.sh --late <window-id> [float-width] [float-height]
#
# --late: the title-changed entry point, a backstop for the case where the
# window is not recognisable as a float until after window_created has been and
# gone. It never runs branch 2 -- an ordinary terminal retitles itself on every
# command, and zooming it each time would be unusable.

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

late=false
if [[ ${1:-} == --late ]]; then
  late=true
  shift
fi

id=${1:?usage: on-window-created.sh [--late] <window-id> [float-w] [float-h]}
w=${2:-875}
h=${3:-600}

# Mirrors the class regex in omarchy default/hypr/apps/system.lua:6-12. On macOS
# every Ghostty window shares one bundle id, so the window title carries the
# identity an app-id carries under Hyprland.
#
# MUST stay byte-identical to the title= of the tui_float rule in
# .config/yabai/yabairc -- that rule decides what is unmanaged, this decides
# what is placed, and `--resize abs` refuses to touch a managed window. A title
# in one list but not the other is either an unplaced float or a no-op.
FLOAT_TITLE='^(org\.omarchy\.(btop|terminal|bash)|TUI\.float|Omarchy|About|Herdr-Keys|LocalSend-Share)$'


# window_created and window_title_changed both fire for a float, within the
# same tick, and both would then act on the same window. `--toggle float` is the
# only float control yabai offers -- there is no `--float` -- so two of them
# cancel out and the window stays tiled, which is exactly the intermittent
# failure this path exists to fix. mkdir is atomic on every filesystem macOS
# ships, so the first signal in does the work and the second returns.
lock="${TMPDIR:-/tmp}/yabai-owc-${id}.lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT

win=$("$YABAI" -m query --windows --window "$id" 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

app=$(printf '%s' "$win" | "$JQ" -r '.app')
title=$(printf '%s' "$win" | "$JQ" -r '.title')
display=$(printf '%s' "$win" | "$JQ" -r '.display')

floating=$(printf '%s' "$win" | "$JQ" -r '."is-floating"')

# Per-float sizes. Omarchy gives every member of its floating-window tag the same
# 875x600; two windows here want otherwise, in opposite directions. The LocalSend
# picker is a deliberate 44x12 cells and stretching it to the Omarchy box is most
# of a screen of empty terminal. btop wants considerably more, because 875x600 is
# only about 76 columns at the 18pt this repo's Ghostty uses -- under btop's
# 80-column floor, and shrinking the font instead would make btop the one
# unreadable terminal on the machine.
#
# These are pixels, here, rather than read back from the window -- which is the
# obvious thing to do, since each TUI's Ghostty config already states its size in
# cells and the terminal is the thing that knows about font metrics. It does not
# survive contact: when the tui_float rule loses its race (below) the window
# arrives already tiled, and the tile frame has overwritten the size the config
# asked for before this script ever sees it. Floating it again does not bring the
# size back -- yabai keeps the tile frame. Measured: reading the window gives the
# right answer about three launches in four and the full space on the fourth.
#
# So the numbers live here, where they are deterministic. The cell counts in
# modules/ghostty/.config/ghostty/*.conf are these same boxes, and exist only so
# the window maps at roughly the right size instead of visibly jumping; keep the
# two in step, and re-measure with `stty size` if the font ever changes.
case $title in
  org.omarchy.btop) w=1359; h=864 ;;   # 117x34 cells at 18pt
  LocalSend-Share)  w=556;  h=336 ;;   # 44x12 cells at 18pt
esac

if [[ $app != Ghostty ]] || ! printf '%s' "$title" | grep -Eq "$FLOAT_TITLE"; then
  # Not a float. On the late path there is nothing to do: this is an ordinary
  # terminal announcing an ordinary title change.
  [[ $late == false ]] || exit 0
  # yabai un-zooms the previously zoomed window when a new one is created, so
  # the newest window is the one filling the space -- the same behaviour
  # AeroSpace got by unfullscreening on the next window.
  [[ $floating == false ]] || exit 0
  "$YABAI" -m window "$id" --toggle zoom-fullscreen 2>/dev/null
  exit 0
fi

# A float whose title arrived after the rule was evaluated is still managed, so
# the rule never declined it. Float it here instead -- `--resize abs` refuses to
# touch a managed window, so this has to come before any measuring.
if [[ $floating == false ]]; then
  "$YABAI" -m window "$id" --toggle float 2>/dev/null || exit 0
fi

# ---------------------------------------------------------------- usable area
# yabai's display frame is the whole panel; centring in it would sit the window
# half a menu bar too high. yabai has no query for the usable rect, but --grid
# is computed over it, so filling the grid once and reading the frame back is an
# exact measurement. Cache it per display: the probe is only visible as a frame
# of full-screen window, and only on the first float after a layout change.
#
# floor() throughout: yabai reports frames as JSON floats, and bash arithmetic
# cannot parse "1512.5".
cache_dir="${HOME}/.cache/yabai"
frame=$("$YABAI" -m query --displays --display "$display" |
           "$JQ" -r '.frame | "\(.x|floor)x\(.y|floor)x\(.w|floor)x\(.h|floor)"')
cache="${cache_dir}/usable-${display}-${frame}"

if [[ -r $cache ]]; then
  read -r ux uy uw uh <"$cache"
else
  "$YABAI" -m window "$id" --grid 1:1:0:0:1:1 2>/dev/null
  read -r ux uy uw uh < <(
    "$YABAI" -m query --windows --window "$id" |
      "$JQ" -r '.frame | "\(.x|floor) \(.y|floor) \(.w|floor) \(.h|floor)"'
  )
  if [[ -n ${uh:-} && $uh != null ]]; then
    mkdir -p "$cache_dir"
    # A resolution change makes a new filename, so stale entries are never read.
    # Sweep the old ones for this display rather than leaving them to pile up.
    find "$cache_dir" -maxdepth 1 -name "usable-${display}-*" ! -name "$(basename "$cache")" -delete 2>/dev/null
    printf '%s %s %s %s\n' "$ux" "$uy" "$uw" "$uh" >"$cache"
  fi
fi

[[ -n ${uw:-} && $uw != null ]] || exit 0

# Never bigger than the screen: Omarchy's 875x600 is comfortable on both the
# Built-in Retina and the DELL, but a smaller display should clamp, not overflow.
(( w > uw )) && w=$uw
(( h > uh )) && h=$uh

x=$(( ux + (uw - w) / 2 ))
y=$(( uy + (uh - h) / 2 ))

# Ghostty can announce a title more than once. Placing an already-placed window
# is invisible, but it would also drag one the user had moved back to the middle
# every time, so a window that is already where this would put it is left alone.
# Queried fresh rather than read out of $win: on a cache miss the --grid probe
# above has resized this very window since, and $win would compare the frame it
# had before that.
read -r cx cy cw ch < <(
  "$YABAI" -m query --windows --window "$id" |
    "$JQ" -r '.frame | "\(.x|floor) \(.y|floor) \(.w|floor) \(.h|floor)"'
)
if [[ $cx == "$x" && $cy == "$y" && $cw == "$w" && $ch == "$h" ]]; then
  exit 0
fi

"$YABAI" -m window "$id" --resize "abs:${w}:${h}"
"$YABAI" -m window "$id" --move "abs:${x}:${y}"
