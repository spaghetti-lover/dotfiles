#!/usr/bin/env bash
#
# Omarchy's Super+L: flip a workspace between layouts, and remember the choice.
#
# Omarchy toggles dwindle <-> scrolling per workspace and persists it in
# ~/.local/state/omarchy/workspace-layouts/. yabai's per-space layouts are bsp
# and stack, and it forgets them on restart, so the persistence is ours.
#
# `stack` here means the WHOLE SPACE becomes one stack -- one window visible,
# the rest behind it. That is a fair analogue of Omarchy's scrolling layout, and
# it is a different thing from the per-window groups on ⌘G (group-toggle.sh).
#
# Bound to ⌘⌥L, not ⌘L: ⌘L stays Open Location.
#
# Usage: layout-memo.sh toggle|restore

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/yabai/layout"

mkdir -p "$STATE"

case "${1:-toggle}" in
  toggle)
    space=$("$YABAI" -m query --spaces --space 2>/dev/null) || exit 0
    label=$(printf '%s' "$space" | "$JQ" -r '.label // empty')
    current=$(printf '%s' "$space" | "$JQ" -r '.type')
    if [[ $current == stack ]]; then new=bsp; else new=stack; fi
    "$YABAI" -m space --layout "$new" || exit 0
    # Unlabelled spaces still toggle, they just are not remembered -- there is
    # no stable key to remember them under.
    [[ -n $label ]] && printf '%s' "$new" > "$STATE/$label"
    ;;
  restore)
    # Called from yabairc AFTER setup-spaces.sh, since the labels have to exist.
    for f in "$STATE"/*; do
      [[ -e $f ]] || continue
      label=$(basename "$f")
      "$YABAI" -m space "$label" --layout "$(cat "$f")" 2>/dev/null
    done
    ;;
  *)
    echo "usage: $0 [toggle|restore]" >&2
    exit 64
    ;;
esac
