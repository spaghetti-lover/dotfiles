#!/usr/bin/env bash
#
# Everything that happens to a new window. Driven by the window_created signal
# in .config/yabai/yabairc, and it does one of two things:
#
#   1. A TUI in the float namespace gets Hyprland's `float + center + size` --
#      the one thing AeroSpace could not do, since it floats a window but has no
#      command to place or resize one.
#   2. Anything else opens zoomed to fill the space, which is what AeroSpace's
#      catch-all `fullscreen --no-outer-gaps` rule did: a new window arrives
#      edge to edge rather than as a tile you then have to enlarge. Its place in
#      the tree is unchanged -- only the drawn frame covers the space.
#
# Usage: on-window-created.sh <window-id> [float-width] [float-height]

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

id=${1:?usage: on-window-created.sh <window-id> [float-w] [float-h]}
w=${2:-875}
h=${3:-600}

# Mirrors the class regex in omarchy default/hypr/apps/system.lua:6-12. On macOS
# every Ghostty window shares one bundle id, so the window title carries the
# identity an app-id carries under Hyprland. Keep in sync with the tui_float
# rule in yabairc -- the rule decides what is unmanaged, this decides what is
# placed, and a window in one set but not the other lands somewhere silly.
FLOAT_TITLE='^(org\.omarchy\.(btop|terminal|bash)|Omarchy|About|TUI\.float)'

win=$("$YABAI" -m query --windows --window "$id" 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

app=$(printf '%s' "$win" | "$JQ" -r '.app')
title=$(printf '%s' "$win" | "$JQ" -r '.title')
display=$(printf '%s' "$win" | "$JQ" -r '.display')

if [[ $app != Ghostty ]] || ! printf '%s' "$title" | grep -Eq "$FLOAT_TITLE"; then
  # Not a float. yabai un-zooms the previously zoomed window when a new one is
  # created, so the newest window is the one filling the space -- the same
  # behaviour AeroSpace got by unfullscreening on the next window.
  managed=$(printf '%s' "$win" | "$JQ" -r '."is-floating"')
  [[ $managed == false ]] || exit 0
  "$YABAI" -m window "$id" --toggle zoom-fullscreen 2>/dev/null
  exit 0
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

"$YABAI" -m window "$id" --resize "abs:${w}:${h}"
"$YABAI" -m window "$id" --move "abs:${x}:${y}"
