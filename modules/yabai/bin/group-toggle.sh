#!/usr/bin/env bash
#
# Omarchy's Super+G: toggle window grouping.
#
# yabai has stacks but no toggle for them, so this is the toggle. A stack is
# one window visible, the others behind it, `stack-index` on every member and
# stack.next / stack.1..N to move between them.
#
# What it does NOT buy is persistence: a stack lives in yabai's in-memory BSP
# tree and dies with the process.
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

  # The warp target has to be OUTSIDE the stack. Warping a member onto another
  # member of the same stack is silently a no-op -- the man page's "any warp
  # unstacks it" holds only for a target that is not itself stacked. Stack
  # members all have stack-index > 0, so this picks a non-member by construction.
  outside=$("$YABAI" -m query --windows --space |
    "$JQ" -r 'map(select(."stack-index" == 0)) | .[0].id // empty')

  for id in "${ids[@]:1}"; do
    if [[ -n $outside ]]; then
      "$YABAI" -m window "$id" --warp "$outside" 2>/dev/null
    else
      # The stack is the whole space, so there is nothing outside it yet.
      # Floating and re-tiling re-inserts this window as a plain leaf.
      # The sleep is load bearing -- see group-eject.sh.
      "$YABAI" -m window "$id" --toggle float 2>/dev/null
      sleep 0.25
      "$YABAI" -m window "$id" --toggle float 2>/dev/null
    fi
    # It is outside the stack now, so it can be the target for the next one.
    outside=$id
  done

  "$YABAI" -m window --focus "$fid" 2>/dev/null
else
  # ---- group with a neighbour ---------------------------------------------
  nid=""
  for dir in east west south north; do
    nid=$("$YABAI" -m query --windows --window "$dir" 2>/dev/null |
      "$JQ" -r 'select(."is-floating" == false) | .id // empty')
    [[ -n $nid ]] && break
  done
  # Only window on the space: silent no-op.
  [[ -n $nid ]] || exit 0

  # Explicit ids, never a direction. `--stack` reads "stack the GIVEN window on
  # top of the SELECTED window", which is the opposite sense to `--warp`, so a
  # DIR_SEL here is ambiguous about which window moves. Ids are not.
  "$YABAI" -m window "$nid" --stack "$fid" 2>/dev/null
  "$YABAI" -m window --focus "$fid" 2>/dev/null

  # Omarchy: "every window you start while the group is active belongs to the
  # group". This is the port of that.
  "$YABAI" -m window --insert stack >/dev/null 2>&1
fi
