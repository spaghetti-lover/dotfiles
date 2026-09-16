#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

target=${1:?usage: $0 next|prev|west|east|north|south}

layout=$("$YABAI" -m query --spaces --space 2>/dev/null | "$JQ" -r '.type // empty')

if [[ $layout == stack ]]; then
  case "$target" in
    prev|west|north) "$YABAI" -m window --focus stack.prev 2>/dev/null ||
                     "$YABAI" -m window --focus stack.last 2>/dev/null ;;
    next|east|south) "$YABAI" -m window --focus stack.next 2>/dev/null ||
                     "$YABAI" -m window --focus stack.first 2>/dev/null ;;
    *) echo "usage: $0 next|prev|west|east|north|south" >&2; exit 64 ;;
  esac
  exit 0
fi

case "$target" in
  next) "$YABAI" -m window --focus next 2>/dev/null ||
        "$YABAI" -m window --focus first 2>/dev/null ;;
  prev) "$YABAI" -m window --focus prev 2>/dev/null ||
        "$YABAI" -m window --focus last 2>/dev/null ;;
  west|east|north|south) "$YABAI" -m window --focus "$target" 2>/dev/null ;;
  *) echo "usage: $0 next|prev|west|east|north|south" >&2; exit 64 ;;
esac

exit 0
