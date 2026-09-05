#!/usr/bin/env bash
#
# Omarchy's "popping" (Super+O) for AeroSpace: pin a window so it floats above
# the tiling tree and follows you onto every workspace you switch to.
#
# AeroSpace has no sticky windows -- https://github.com/nikitabobko/AeroSpace/issues/2
# -- so this fakes one. `toggle` floats the focused window and records its id;
# `exec-on-workspace-change` then calls `follow`, which drags that window onto
# the workspace you just switched to. See aerospace/.config/aerospace/aerospace.toml.
#
# Limits, deliberately:
#   - ONE pinned window at a time. Omarchy allows several; pinning a second
#     window releases the first.
#   - The move happens just after the workspace switch, so the window flicks
#     into place rather than being there already.
#
# `move-node-to-workspace` does not change the focused workspace, so `follow`
# cannot re-trigger itself.
#
# Usage (AeroSpace calls these; you should not need to):
#   ./aerospace-pin.sh toggle    pin / unpin the focused window
#   ./aerospace-pin.sh follow    bring the pinned window to $AEROSPACE_FOCUSED_WORKSPACE
#   ./aerospace-pin.sh clear     forget the pin

set -uo pipefail

# Absolute: exec-on-workspace-change does not run in a login shell.
AEROSPACE=/opt/homebrew/bin/aerospace
STATE="${HOME}/.cache/aerospace/pinned-window"

unpin() { # $1 = window id
  "$AEROSPACE" layout tiling --window-id "$1" >/dev/null 2>&1
  rm -f "$STATE"
}

case "${1:-}" in
  toggle)
    id=$("$AEROSPACE" list-windows --focused --format '%{window-id}' 2>/dev/null) || exit 0
    [ -n "$id" ] || exit 0

    pinned=$(cat "$STATE" 2>/dev/null)
    if [ "$pinned" = "$id" ]; then
      unpin "$id"
      exit 0
    fi

    # Only one pin at a time: release the previous one first.
    [ -n "$pinned" ] && unpin "$pinned"

    mkdir -p "$(dirname "$STATE")"
    printf '%s' "$id" > "$STATE"
    "$AEROSPACE" layout floating --window-id "$id"
    ;;

  follow)
    id=$(cat "$STATE" 2>/dev/null) || exit 0
    [ -n "$id" ] || exit 0
    [ -n "${AEROSPACE_FOCUSED_WORKSPACE:-}" ] || exit 0

    # The window may have been closed while pinned; forget it if so.
    if ! "$AEROSPACE" list-windows --all --format '%{window-id}' | grep -qx "$id"; then
      rm -f "$STATE"
      exit 0
    fi

    "$AEROSPACE" move-node-to-workspace --window-id "$id" "$AEROSPACE_FOCUSED_WORKSPACE"
    ;;

  clear)
    rm -f "$STATE"
    ;;

  *)
    echo "usage: $0 [toggle|follow|clear]" >&2
    exit 64
    ;;
esac
