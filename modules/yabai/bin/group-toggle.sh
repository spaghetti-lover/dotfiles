#!/usr/bin/env bash
#
# Omarchy's Super+G: toggle window grouping.
#
# yabai has stacks but no toggle for them, so this is the toggle. A stack is a
# real thing here -- one window visible, the others behind it, `stack-index` on
# every member and stack.next / stack.1..N to move between them -- where the
# AeroSpace config could only approximate it with an accordion container.
#
# What it does NOT buy is persistence: a stack lives in yabai's in-memory BSP
# tree and dies with the process, exactly as AeroSpace's accordion did. See
# docs/yabai.md.
#
# Membership is enumerated through STACK_SEL relative to the focused window
# rather than by comparing frames, so it is exact at any depth.

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
JQ=/opt/homebrew/bin/jq

win=$("$YABAI" -m query --windows --window 2>/dev/null) || exit 0
[[ -n $win ]] || exit 0

fid=$(printf '%s' "$win" | "$JQ" -r '.id')
si=$(printf '%s' "$win" | "$JQ" -r '."stack-index" // 0')

if (( si > 0 )); then
  # ---- ungroup ------------------------------------------------------------
  # Walk stack.1, stack.2, ... until the selector stops resolving, then warp
  # every member off the base. Any warp on a stacked window unstacks it, so the
  # stack unravels one leaf at a time.
  ids=()
  n=1
  while true; do
    id=$("$YABAI" -m query --windows --window "stack.$n" 2>/dev/null | "$JQ" -r '.id // empty')
    [[ -n $id ]] || break
    ids+=("$id")
    n=$(( n + 1 ))
    (( n > 64 )) && break        # paranoia: never spin on a selector that always resolves
  done

  (( ${#ids[@]} > 1 )) || exit 0
  base=${ids[0]}
  for id in "${ids[@]}"; do
    [[ $id == "$base" ]] && continue
    "$YABAI" -m window "$id" --warp "$base" 2>/dev/null
  done

  # Clear the stack insertion mode set below, so new windows tile again.
  "$YABAI" -m window "$fid" --insert east >/dev/null 2>&1
  "$YABAI" -m window --focus "$fid" 2>/dev/null
else
  # ---- group with a neighbour ---------------------------------------------
  nid=""
  for dir in east west south north; do
    nid=$("$YABAI" -m query --windows --window "$dir" 2>/dev/null |
      "$JQ" -r 'select(."is-floating" == false) | .id // empty')
    [[ -n $nid ]] && break
  done
  # Only window on the space: silent no-op, as AeroSpace was.
  [[ -n $nid ]] || exit 0

  # Explicit ids, never a direction. `--stack` reads "stack the GIVEN window on
  # top of the SELECTED window", which is the opposite sense to `--warp`, so a
  # DIR_SEL here is ambiguous about which window moves. Ids are not.
  "$YABAI" -m window "$nid" --stack "$fid" 2>/dev/null
  "$YABAI" -m window --focus "$fid" 2>/dev/null

  # Omarchy: "every window you start while the group is active belongs to the
  # group". This is the port of that, and of the AeroSpace rule that tested
  # window-parent-container-layout ~= accordion.
  "$YABAI" -m window --insert stack >/dev/null 2>&1
fi
