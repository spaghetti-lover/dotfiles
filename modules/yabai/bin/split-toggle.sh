#!/usr/bin/env bash
#
# Omarchy's Super+J -- Hyprland's `togglesplit`. Flips the focused window's
# split with its parent node, so a side-by-side pair becomes a stacked one and
# back, leaving the rest of the tree alone.
#
# `yabai -m window --toggle split` is the whole of it on paper, and bound bare
# it looks broken. Two reasons, both real:
#
#   1. A zoomed window is drawn over the whole space, so the flip underneath is
#      invisible -- measured directly, split-type goes vertical -> horizontal
#      and the sibling re-tiles from 882x1109 to 1770x552 with nothing visibly
#      changing. yabairc sets window_zoom_persist on, so a zoom from cmd-ctrl-f
#      or cmd-alt-f sticks around to do exactly that. The zoom is cleared first.
#   2. A window alone in its space has no parent to split with -- split-type is
#      `none` -- and yabai answers with an error on stderr. Hyprland no-ops
#      silently in the same case, so this does too.
#
# Deliberate: cmd-ctrl-f and cmd-alt-f stay the way to zoom on purpose. This
# only clears a zoom that is in the way of the thing you actually asked for.

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq
BIN=$(dirname "$0")

space=$("$YABAI" -m query --spaces --space 2>/dev/null)
if [[ -n $space ]] && [[ $(printf '%s' "$space" | "$JQ" -r '.type') == stack ]]; then
  "$BIN/layout-memo.sh" set bsp
  exec "$BIN/focus.sh" next
fi

win=$("$YABAI" -m query --windows --window 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

read -r split zoom_fullscreen zoom_parent floating < <(
  printf '%s' "$win" | "$JQ" -r '"\(."split-type") \(."has-fullscreen-zoom") \(."has-parent-zoom") \(."is-floating")"'
)

# A float has no place in the tree at all, so there is no split to flip. alt-t
# (Omarchy's Super+T, moved off cmd-t so that stays New Tab) tiles it again.
[[ $floating == false ]] || exit 0

# Alone in the space. Nothing to toggle, and nothing worth logging.
[[ $split != none ]] || exit 0

# The two zooms are not independent flags. With a two-window space the parent
# IS the space, so clearing zoom-fullscreen clears has-parent-zoom with it, and
# a second unconditional toggle would zoom the window straight back in -- which
# is measurably what happens. Clear one, look again, and only then decide.
if [[ $zoom_fullscreen == true ]]; then
  "$YABAI" -m window --toggle zoom-fullscreen 2>/dev/null
  zoom_parent=$("$YABAI" -m query --windows --window 2>/dev/null |
                  "$JQ" -r '."has-parent-zoom"')
fi
[[ $zoom_parent == true ]] && "$YABAI" -m window --toggle zoom-parent 2>/dev/null

"$YABAI" -m window --toggle split
