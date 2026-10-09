#!/usr/bin/env bash

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

[[ $floating == false ]] || exit 0

[[ $split != none ]] || exit 0

if [[ $zoom_fullscreen == true ]]; then
  "$YABAI" -m window --toggle zoom-fullscreen 2>/dev/null
  zoom_parent=$("$YABAI" -m query --windows --window 2>/dev/null |
    "$JQ" -r '."has-parent-zoom"')
fi
[[ $zoom_parent == true ]] && "$YABAI" -m window --toggle zoom-parent 2>/dev/null

"$YABAI" -m window --toggle split
