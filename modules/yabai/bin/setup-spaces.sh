#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

LABELS=(ws1 ws2 ws3 ws4 ws5 ws6 ws7 ws8 ws9 scratch)

main=$("$YABAI" -m query --displays 2>/dev/null |
  "$JQ" -r 'map(select(.frame.x == 0 and .frame.y == 0)) | .[0].index // empty')
[[ -n ${main:-} ]] || main=$("$YABAI" -m query --displays --display 2>/dev/null | "$JQ" -r '.index')
[[ -n ${main:-} && $main != null ]] || exit 0

"$YABAI" -m display "$main" --label main 2>/dev/null

spaces_on_main() { "$YABAI" -m query --spaces --display "$main" | "$JQ" -r '.[].index'; }

have=$(spaces_on_main | wc -l | tr -d ' ')
want=${#LABELS[@]}

if ((have < want)); then
  for ((i = have; i < want; i++)); do
    "$YABAI" -m space --create "$main" 2>/dev/null || break
  done
fi

spaces=()
while IFS= read -r index; do
  [[ -n $index ]] && spaces+=("$index")
done < <(spaces_on_main)

i=0
for label in "${LABELS[@]}"; do
  [[ -n ${spaces[i]:-} ]] || break
  current=$("$YABAI" -m query --spaces --space "${spaces[i]}" | "$JQ" -r '.label')
  [[ $current == "$label" ]] || "$YABAI" -m space "${spaces[i]}" --label "$label" 2>/dev/null
  i=$((i + 1))
done

for label in "${LABELS[@]}"; do
  where=$("$YABAI" -m query --spaces --space "$label" 2>/dev/null | "$JQ" -r '.display // empty')
  [[ -n $where && $where != "$main" ]] || continue
  "$YABAI" -m space "$label" --display "$main" 2>/dev/null
done
