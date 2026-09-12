#!/usr/bin/env bash
#
# Omarchy's Super+Alt+<arrow>: pull the window in that direction into a group
# with the focused one.
#
# Usage: group-join.sh <north|south|east|west>

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

dir=${1:?usage: group-join.sh <north|south|east|west>}

fid=$("$YABAI" -m query --windows --window 2>/dev/null | "$JQ" -r '.id // empty')
[[ -n $fid ]] || exit 0

nid=$("$YABAI" -m query --windows --window "$dir" 2>/dev/null |
  "$JQ" -r 'select(."is-floating" == false) | .id // empty')
[[ -n $nid ]] || exit 0

# See group-toggle.sh: ids, not a DIR_SEL, because --stack and --warp disagree
# about which of the two windows moves.
"$YABAI" -m window "$nid" --stack "$fid" 2>/dev/null
"$YABAI" -m window --focus "$fid" 2>/dev/null
"$YABAI" -m window --insert stack >/dev/null 2>&1
