#!/usr/bin/env bash

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

if [[ ${1:-} == --late ]]; then
  shift
fi

id=${1:?usage: on-window-created.sh [--late] <window-id> [float-w] [float-h]}
w=${2:-875}
h=${3:-600}

# Keep this pattern aligned with yabairc’s tui_float rule.
FLOAT_TITLE='^(org\.omarchy\.(btop|terminal|bash)|TUI\.float|Omarchy|About)$'

# Both window signals can fire together; toggling twice would undo floating.
lock="${TMPDIR:-/tmp}/yabai-owc-${id}.lock"
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT

win=$("$YABAI" -m query --windows --window "$id" 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

app=$(printf '%s' "$win" | "$JQ" -r '.app')
title=$(printf '%s' "$win" | "$JQ" -r '.title')
display=$(printf '%s' "$win" | "$JQ" -r '.display')

floating=$(printf '%s' "$win" | "$JQ" -r '."is-floating"')

case $title in
  org.omarchy.btop)
    w=1359
    h=864
    ;; # 117x34 cells at 18pt
esac

if [[ $app != Ghostty ]] || ! printf '%s' "$title" | grep -Eq "$FLOAT_TITLE"; then
  exit 0
fi

if [[ $floating == false ]]; then
  "$YABAI" -m window "$id" --toggle float 2>/dev/null || exit 0
fi

cache_dir="${HOME}/.cache/yabai"
frame=$("$YABAI" -m query --displays --display "$display" |
  "$JQ" -r '.frame | "\(.x|floor)x\(.y|floor)x\(.w|floor)x\(.h|floor)"')
cache="${cache_dir}/usable-${display}-${frame}"

if [[ -r $cache ]]; then
  read -r ux uy uw uh <"$cache"
else
  "$YABAI" -m window "$id" --grid 1:1:0:0:1:1 2>/dev/null
  read -r ux uy uw uh < <(
    "$YABAI" -m query --windows --window "$id" |
      "$JQ" -r '.frame | "\(.x|floor) \(.y|floor) \(.w|floor) \(.h|floor)"'
  )
  if [[ -n ${uh:-} && $uh != null ]]; then
    mkdir -p "$cache_dir"
    find "$cache_dir" -maxdepth 1 -name "usable-${display}-*" ! -name "$(basename "$cache")" -delete 2>/dev/null
    printf '%s %s %s %s\n' "$ux" "$uy" "$uw" "$uh" >"$cache"
  fi
fi

[[ -n ${uw:-} && $uw != null ]] || exit 0

((w > uw)) && w=$uw
((h > uh)) && h=$uh

x=$((ux + (uw - w) / 2))
y=$((uy + (uh - h) / 2))

read -r cx cy cw ch < <(
  "$YABAI" -m query --windows --window "$id" |
    "$JQ" -r '.frame | "\(.x|floor) \(.y|floor) \(.w|floor) \(.h|floor)"'
)
if [[ $cx == "$x" && $cy == "$y" && $cw == "$w" && $ch == "$h" ]]; then
  exit 0
fi

"$YABAI" -m window "$id" --resize "abs:${w}:${h}"
"$YABAI" -m window "$id" --move "abs:${x}:${y}"
