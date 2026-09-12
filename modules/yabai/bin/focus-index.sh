#!/usr/bin/env bash
#
# Super+Alt+N: jump to the Nth window on the current space, depth-first. yabai
# has no index selector, so walk its window list.
#
# The wanted order is top to bottom then left to right, which is the order a
# group shows its windows in. yabai's query is not tree-ordered, so sort by
# position instead -- same answer for every layout where the two could differ
# visibly.
#
# Usage: focus-index.sh <1-based index>

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
