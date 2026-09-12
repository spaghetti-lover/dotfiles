#!/usr/bin/env bash
#
# AeroSpace's `close-all-windows-but-current` (Ctrl+Alt+Backspace), and the
# `backspace` key of service mode.
#
# yabai closes one window at a time, so this collects the ids first: closing
# while iterating a live query would drop windows as the list shifts underneath.

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

focused=$("$YABAI" -m query --windows --window 2>/dev/null | "$JQ" -r '.id') || exit 0
[[ -n $focused && $focused != null ]] || exit 0

ids=$("$YABAI" -m query --windows --space | "$JQ" -r --argjson keep "$focused" '
  .[] | select(.id != $keep) | select(."is-minimized" == false) | .id
') || exit 0

for id in $ids; do
  "$YABAI" -m window "$id" --close 2>/dev/null
done
