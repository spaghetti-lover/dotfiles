#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

win=$("$YABAI" -m query --windows --window 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

fid=$(printf '%s' "$win" | "$JQ" -r '.id')
si=$(printf '%s' "$win" | "$JQ" -r '."stack-index" // 0')

if ((si > 0)); then
  ids=()
  n=1
  while true; do
    id=$("$YABAI" -m query --windows --window "stack.$n" 2>/dev/null | "$JQ" -r '.id // empty')
    [[ -n $id ]] || break
    ids+=("$id")
    n=$((n + 1))
    ((n > 64)) && break # paranoia: never spin on a selector that always resolves
  done

  ((${#ids[@]} > 1)) || exit 0

  outside=$("$YABAI" -m query --windows --space |
    "$JQ" -r 'map(select(."stack-index" == 0)) | .[0].id // empty')

  for id in "${ids[@]:1}"; do
    if [[ -n $outside ]]; then
      "$YABAI" -m window "$id" --warp "$outside" 2>/dev/null
    else
      "$YABAI" -m window "$id" --toggle float 2>/dev/null
      # Let the window server finish floating before reinserting the tile.
      sleep 0.25
      "$YABAI" -m window "$id" --toggle float 2>/dev/null
    fi
    outside=$id
  done

  "$YABAI" -m window --focus "$fid" 2>/dev/null
else
  nid=""
  for dir in east west south north; do
    nid=$("$YABAI" -m query --windows --window "$dir" 2>/dev/null |
      "$JQ" -r 'select(."is-floating" == false) | .id // empty')
    [[ -n $nid ]] && break
  done
  [[ -n $nid ]] || exit 0

  "$YABAI" -m window "$nid" --stack "$fid" 2>/dev/null
  "$YABAI" -m window --focus "$fid" 2>/dev/null

  "$YABAI" -m window --insert stack >/dev/null 2>&1
fi
