#!/usr/bin/env bash
#
# ⌘Tab / ⌘⇧Tab: next and previous workspace, wrapping, and confined to the
# display you are on.
#
# Two reasons this is not just `space --focus next`. yabai's next/prev do not
# wrap -- they fail at the ends of the list -- and the list is every space on
# every display, so on a two-monitor setup a bare next walks off onto the DELL.
# AeroSpace's `workspace --wrap-around next` did neither.
#
# The recipe is the one from the yabai wiki's Tips and Tricks, as one script
# with an argument.
#
# Usage: space-cycle.sh next|prev

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

dir=${1:-next}
info=$("$YABAI" -m query --spaces --display 2>/dev/null) || exit 0
[[ -n $info ]] || exit 0

case "$dir" in
  next)
    if [[ $(printf '%s' "$info" | "$JQ" '.[-1]."has-focus"') == false ]]; then
      "$YABAI" -m space --focus next
    else
      "$YABAI" -m space --focus "$(printf '%s' "$info" | "$JQ" '.[0].index')"
    fi
    ;;
  prev)
    if [[ $(printf '%s' "$info" | "$JQ" '.[0]."has-focus"') == false ]]; then
      "$YABAI" -m space --focus prev
    else
      "$YABAI" -m space --focus "$(printf '%s' "$info" | "$JQ" '.[-1].index')"
    fi
    ;;
  *)
    echo "usage: $0 [next|prev]" >&2
    exit 64
    ;;
esac
