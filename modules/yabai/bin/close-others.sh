#!/usr/bin/env bash

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
