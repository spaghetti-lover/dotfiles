#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

n=${1:?usage: focus-index.sh <n>}

id=$("$YABAI" -m query --windows --space 2>/dev/null | "$JQ" -r --argjson n "$n" '
  [ .[]
    | select(."is-minimized" == false)
    | select(."is-hidden" == false)
  ]
  | sort_by(.frame.y, .frame.x)
  | .[$n - 1].id // empty
') || exit 0

[[ -n $id ]] || exit 0
"$YABAI" -m window --focus "$id"
