#!/usr/bin/env bash
#
# Usage: resize.sh <h|v> <delta>

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

axis=${1:?usage: resize.sh <h|v> <delta>}
delta=${2:?usage: resize.sh <h|v> <delta>}

win=$("$YABAI" -m query --windows --window 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

if [[ $("$JQ" -r '."is-floating"' <<<"$win") == true ]]; then
  case $axis in
    h) "$YABAI" -m window --resize bottom_right:"$delta":0 2>/dev/null ;;
    v) "$YABAI" -m window --resize bottom_right:0:"$delta" 2>/dev/null ;;
  esac
  exit 0
fi

wid=$("$JQ" -r '.id' <<<"$win")
sid=$("$JQ" -r '.space' <<<"$win")

fences=$("$YABAI" -m query --windows --space "$sid" 2>/dev/null | "$JQ" -r --argjson id "$wid" '
  [ .[] | select(."is-floating" == false and ."is-minimized" == false) ] as $tiled
  | ( [ $tiled[] | .frame.x + .frame.w ] | max ) as $right
  | ( [ $tiled[] | .frame.y + .frame.h ] | max ) as $bottom
  | ( $tiled[] | select(.id == $id) ) as $me
  | "\($me.frame.x + $me.frame.w < $right - 1) \($me.frame.y + $me.frame.h < $bottom - 1)"
') || exit 0

read -r east south <<<"$fences"

if [[ $axis == h ]]; then
  if [[ $east == true ]]; then
    "$YABAI" -m window --resize right:"$delta":0 2>/dev/null
  else
    "$YABAI" -m window --resize left:"$((-delta))":0 2>/dev/null
  fi
else
  if [[ $south == true ]]; then
    "$YABAI" -m window --resize bottom:0:"$delta" 2>/dev/null
  else
    "$YABAI" -m window --resize top:0:"$((-delta))" 2>/dev/null
  fi
fi
