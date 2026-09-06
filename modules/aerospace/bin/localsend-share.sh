#!/usr/bin/env bash
# Omarchy's Share menu for macOS -- see docs/keybindings.md#sharing-files.

set -euo pipefail

APP="LocalSend"
STAGE="${TMPDIR:-/tmp}/localsend-share"

die() { printf '\033[31m%s\033[0m\n' "$1" >&2; sleep 3; exit 1; }

pick() {
  osascript 2>/dev/null <<OSA || true
    tell application "System Events" to activate
    set out to ""
    repeat with f in ($1)
      set out to out & POSIX path of f & linefeed
    end repeat
    return out
OSA
}

stage_clipboard() {
  mkdir -p "$STAGE"
  local out="$STAGE/clipboard-$(date +%Y%m%d-%H%M%S)" text
  text=$(pbpaste 2>/dev/null || true)
  if [[ -n "$text" ]]; then
    printf '%s\n' "$text" >"$out.txt"
    printf '%s\n' "$out.txt"
    return 0
  fi
  osascript -e 'set png to (the clipboard as «class PNGf»)' \
            -e "set f to open for access POSIX file \"$out.png\" with write permission" \
            -e 'write png to f' \
            -e 'close access f' >/dev/null 2>&1 || true
  [[ -s "$out.png" ]] || { rm -f "$out.png"; return 1; }
  printf '%s\n' "$out.png"
}

command -v fzf >/dev/null || die "fzf not found -- brew bundle install --file=install/Brewfile"
[[ -d "/Applications/$APP.app" ]] || die "$APP.app not installed -- brew install --cask localsend"

# AeroSpace's catch-all fullscreens this window; undo it once it exists.
if command -v aerospace >/dev/null; then
  ( sleep 0.4; aerospace fullscreen off; aerospace layout floating ) >/dev/null 2>&1 &
fi

choice=$(printf '%s\n' Clipboard File Folder Receive |
  fzf --prompt='> ' --header=$'Share…\n' --header-first \
      --reverse --no-info --pointer='>' --color='gutter:-1' || true)

paths=()
case "$choice" in
  Clipboard) paths=("$(stage_clipboard)") || die "Clipboard is empty (no text and no image)" ;;
  File)      spec='choose file with prompt "Send with LocalSend" with multiple selections allowed' ;;
  Folder)    spec='{choose folder with prompt "Send a folder with LocalSend"}' ;;
  Receive)   ;;
  *)         exit 0 ;;
esac

if [[ -n "${spec:-}" ]]; then
  while IFS= read -r p; do
    if [[ -n "$p" ]]; then paths+=("$p"); fi
  done < <(pick "$spec")
  [[ ${#paths[@]} -gt 0 ]] || exit 0
fi

open -a "$APP" ${paths[@]+"${paths[@]}"}
