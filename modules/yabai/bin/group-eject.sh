#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

win=$("$YABAI" -m query --windows --window 2>/dev/null) || exit 0
si=$(printf '%s' "$win" | "$JQ" -r '."stack-index" // 0')
((si > 0)) || exit 0 # not in a group: nothing to leave

target=$("$YABAI" -m query --windows --window sibling 2>/dev/null | "$JQ" -r '.id // empty')

if [[ -n $target ]]; then
  "$YABAI" -m window --warp "$target" 2>/dev/null
else
  "$YABAI" -m window --toggle float 2>/dev/null || exit 0
  # Let the window server finish floating before reinserting the tile.
  sleep 0.25
  "$YABAI" -m window --toggle float 2>/dev/null
fi
