#!/usr/bin/env bash
#
# Omarchy's Super+Alt+G: push the focused window back out of its group.
#
# The inverse of group-join.sh. yabai has `sibling` as a window selector, which
# resolves to the stack node's BSP sibling -- the surrounding container -- so
# there is nothing to aim.

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

win=$("$YABAI" -m query --windows --window 2>/dev/null) || exit 0
si=$(printf '%s' "$win" | "$JQ" -r '."stack-index" // 0')
(( si > 0 )) || exit 0          # not in a group: nothing to leave

target=$("$YABAI" -m query --windows --window sibling 2>/dev/null | "$JQ" -r '.id // empty')

if [[ -n $target ]]; then
  # Any warp on a stacked window unstacks it.
  "$YABAI" -m window --warp "$target" 2>/dev/null
else
  # The stack is the only node on the space, so there is no sibling to warp to.
  # Float and unfloat re-inserts the window into the tree as a plain leaf.
  #
  # The sleep is load bearing: back to back, the second toggle fires before the
  # window server has settled the first and the window lands back in the stack.
  "$YABAI" -m window --toggle float 2>/dev/null || exit 0
  sleep 0.25
  "$YABAI" -m window --toggle float 2>/dev/null
fi
