#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/yabai/layout"

mkdir -p "$STATE"

apply() {
  local new=$1 label
  label=$(printf '%s' "$space" | "$JQ" -r '.label // empty')
  "$YABAI" -m space --layout "$new" 2>/dev/null || return 0
  [[ -n $label ]] && printf '%s' "$new" >"$STATE/$label"
  return 0
}

case "${1:-toggle}" in
  toggle)
    space=$("$YABAI" -m query --spaces --space 2>/dev/null) || exit 0
    current=$(printf '%s' "$space" | "$JQ" -r '.type')
    if [[ $current == stack ]]; then apply bsp; else apply stack; fi
    ;;
  set)
    case "${2:-}" in
      bsp | stack) ;;
      *)
        echo "usage: $0 set bsp|stack" >&2
        exit 64
        ;;
    esac
    space=$("$YABAI" -m query --spaces --space 2>/dev/null) || exit 0
    apply "$2"
    ;;
  restore)
    for f in "$STATE"/*; do
      [[ -e $f ]] || continue
      label=$(basename "$f")
      "$YABAI" -m space "$label" --layout "$(cat "$f")" 2>/dev/null
    done
    ;;
  *)
    echo "usage: $0 [toggle|restore|set bsp|stack]" >&2
    exit 64
    ;;
esac
