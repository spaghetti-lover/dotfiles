#!/usr/bin/env bash
#
# Ten labelled spaces on the main display: ws1..ws9 plus scratch.
#
# skhd binds ⌘1..9 to LABELS rather than Mission Control indices on purpose:
# indices are global across displays and shift whenever a space is created or
# destroyed anywhere, so `space --focus 3` stops meaning workspace 3 the moment
# you add a space on the DELL. A label survives all of that -- but not a yabai
# restart, which is why this runs from yabairc on every start.
#
# This stands in for AeroSpace's [workspace-to-monitor-force-assignment], and
# only partly. AeroSpace workspaces are virtual and could be pinned to `main` by
# config; macOS spaces BELONG to a display and the only lever is the imperative
# `space <label> --display`. See the drift-correction pass at the bottom, and
# docs/yabai.md for what it cannot promise.
#
# Idempotent and never destructive: it creates spaces up to the target count and
# labels them, but extra spaces you made by hand are left alone -- destroying a
# space silently relocates its windows, which is not a thing a startup script
# should do. `make yabai-spaces-prune` is the explicit way to remove them.
#
# Needs SIP partially disabled: `space --create` and `space --display` are both
# scripting-addition commands. The labelling half works without it, so on a
# machine with a broken addition you create the spaces by hand once in Mission
# Control and this still wires ⌘1..9 up to them.

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

LABELS=(ws1 ws2 ws3 ws4 ws5 ws6 ws7 ws8 ws9 scratch)

# The main display is the one at the global origin -- that is what "main" means
# in macOS display coordinates. The WIP used the FOCUSED display, which makes
# provisioning depend on where the mouse happened to be when yabai started.
main=$("$YABAI" -m query --displays 2>/dev/null |
  "$JQ" -r 'map(select(.frame.x == 0 and .frame.y == 0)) | .[0].index // empty')
[[ -n ${main:-} ]] || main=$("$YABAI" -m query --displays --display 2>/dev/null | "$JQ" -r '.index')
[[ -n ${main:-} && $main != null ]] || exit 0

"$YABAI" -m display "$main" --label main 2>/dev/null

spaces_on_main() { "$YABAI" -m query --spaces --display "$main" | "$JQ" -r '.[].index'; }

have=$(spaces_on_main | wc -l | tr -d ' ')
want=${#LABELS[@]}

# Too few: make up the difference. Bail on the first failure rather than
# retrying -- a failure here means the scripting addition is not loaded, and
# every subsequent call would fail the same way.
if (( have < want )); then
  for (( i = have; i < want; i++ )); do
    "$YABAI" -m space --create "$main" 2>/dev/null || break
  done
fi
# Too many: deliberately nothing. See the header.

# Label in Mission Control order, so ws1 is the leftmost space. Relabelling a
# space that already carries the label is skipped -- it is a no-op either way,
# but this keeps the common case down to one query per space.
#
# `while read` rather than mapfile: macOS ships bash 3.2, which has neither
# mapfile nor readarray.
spaces=()
while IFS= read -r index; do
  [[ -n $index ]] && spaces+=("$index")
done < <(spaces_on_main)

i=0
for label in "${LABELS[@]}"; do
  [[ -n ${spaces[i]:-} ]] || break
  current=$("$YABAI" -m query --spaces --space "${spaces[i]}" | "$JQ" -r '.label')
  [[ $current == "$label" ]] || "$YABAI" -m space "${spaces[i]}" --label "$label" 2>/dev/null
  i=$(( i + 1 ))
done

# Drift correction. macOS reassigns spaces to displays on hot-plug, and it does
# so BEFORE yabai reports display_added, so there is a window in which ⌘1..9
# lands on the wrong screen. Dragging the space back re-parents it and every
# window on it, which is a visible jump -- accepted, because the alternative is
# digit keys that silently point somewhere else.
for label in "${LABELS[@]}"; do
  where=$("$YABAI" -m query --spaces --space "$label" 2>/dev/null | "$JQ" -r '.display // empty')
  [[ -n $where && $where != "$main" ]] || continue
  "$YABAI" -m space "$label" --display "$main" 2>/dev/null
done
