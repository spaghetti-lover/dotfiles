#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

w=${1:-1300} # omarchy-hyprland-window-pop's defaults
h=${2:-900}

win=$("$YABAI" -m query --windows --window 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

id=$(printf '%s' "$win" | "$JQ" -r '.id')
sticky=$(printf '%s' "$win" | "$JQ" -r '."is-sticky"')

if [[ $sticky == true ]]; then
  "$YABAI" -m window "$id" --toggle sticky
  "$YABAI" -m window "$id" --sub-layer auto # auto, not normal: normal is permanent
  "$YABAI" -m window "$id" --toggle float
  exit 0
fi

"$YABAI" -m window "$id" --toggle float

"$YABAI" -m window "$id" --grid 1:1:0:0:1:1 2>/dev/null
read -r ux uy uw uh < <(
  "$YABAI" -m query --windows --window "$id" |
    "$JQ" -r '.frame | "\(.x|floor) \(.y|floor) \(.w|floor) \(.h|floor)"'
)

if [[ -n ${uw:-} && $uw != null ]]; then
  ((w > uw)) && w=$uw
  ((h > uh)) && h=$uh
  "$YABAI" -m window "$id" --resize "abs:${w}:${h}"
  "$YABAI" -m window "$id" --move "abs:$((ux + (uw - w) / 2)):$((uy + (uh - h) / 2))"
fi

"$YABAI" -m window "$id" --toggle sticky
"$YABAI" -m window "$id" --sub-layer above
