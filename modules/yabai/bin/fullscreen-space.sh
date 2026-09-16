#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq
BIN=$(dirname "$0")

space=$("$YABAI" -m query --spaces --space 2>/dev/null) || exit 0
[[ -n $space ]] || exit 0

if [[ $(printf '%s' "$space" | "$JQ" -r '.type') == stack ]]; then
  exec "$BIN/layout-memo.sh" set bsp
fi

win=$("$YABAI" -m query --windows --window 2>/dev/null)
if [[ -n $win ]]; then
  read -r zoom_fullscreen zoom_parent < <(
    printf '%s' "$win" | "$JQ" -r '"\(."has-fullscreen-zoom") \(."has-parent-zoom")"'
  )
  if [[ $zoom_fullscreen == true ]]; then
    "$YABAI" -m window --toggle zoom-fullscreen 2>/dev/null
    zoom_parent=$("$YABAI" -m query --windows --window 2>/dev/null |
                    "$JQ" -r '."has-parent-zoom"')
  fi
  [[ $zoom_parent == true ]] && "$YABAI" -m window --toggle zoom-parent 2>/dev/null
fi

exec "$BIN/layout-memo.sh" set stack
