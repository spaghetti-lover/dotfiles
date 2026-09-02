#!/usr/bin/env bash
#
# Restore the macOS menu commands that AeroSpace's Omarchy bindings take over.
#
# AeroSpace grabs cmd-* globally (see aerospace/.config/aerospace/aerospace.toml),
# so cmd-O, cmd-G, cmd-S, cmd-P and cmd-+/- never reach an app. (cmd-F is not
# among them any more -- nothing is bound to it, so Find works natively.)
# This puts those commands back on plain ctrl -- the Linux convention, which is
# what Omarchy users expect anyway.
#
# Running this is NOT optional. cmd-S is the scratchpad toggle now, so any app
# missing from APPS below has no Save shortcut at all -- only File > Save in its
# own menu. Add apps here as you install them.
#
# Mechanism: NSUserKeyEquivalents rebinds a menu item by its exact title. It
# works at the AppKit menu layer, NOT the key-event layer, which is why it can
# coexist with AeroSpace's global grab.
#
# IMPORTANT: this is deliberately PER-APP, never `defaults write -g`.
#   ctrl-F  is zsh autosuggest-accept
#   ctrl-L / ctrl-J / ctrl-K are vim-tmux-navigator motions
#   ctrl-S  is XOFF, which freezes the terminal
# A global write would steal those inside WezTerm and Ghostty, so terminal
# bundle IDs are deliberately absent from APPS below.
#
# Not recoverable: cmd-1..9 for browser tab selection. Browsers expose no menu
# item for "switch to tab N", so there is nothing to rebind. Use ctrl-Tab /
# ctrl-shift-Tab, which cycle tabs natively.
#
# Usage:
#   ./macos-app-shortcuts.sh          apply
#   ./macos-app-shortcuts.sh --list   show what is currently set
#   ./macos-app-shortcuts.sh --reset  remove everything this script sets
#
# Modifier syntax: @ cmd   ^ ctrl   ~ option   $ shift

set -uo pipefail

# GUI apps only. Terminals are excluded on purpose -- see the note above.
APPS=(
  com.brave.Browser
  com.google.Chrome
  org.mozilla.firefox
  com.apple.Safari
  com.apple.finder
  com.apple.Preview
  com.apple.Notes
  com.apple.mail
  com.apple.iCal
  com.apple.TextEdit
  info.sioyek.sioyek
  net.kovidgoyal.calibre
  net.ankiweb.anki
  com.postmanlabs.mac
  com.hnc.Discord
  com.google.GeminiMacOS
  com.microsoft.VSCode
  com.apple.dt.Xcode
  com.apple.Pages
  com.apple.Numbers
  com.apple.Keynote
  com.apple.iMovieApp
  com.apple.garageband10
  com.obsproject.obs-studio
)

# "Menu item title|shortcut". Titles must match the menu bar EXACTLY, so the
# ellipsis items are written twice: once with U+2026 and once with three
# periods, since apps are inconsistent. Writing a title an app does not have
# is a harmless no-op.
BINDINGS=(
  'Find Next|^g'
  'Open…|^o'
  'Open...|^o'
  'Open File…|^o'
  'Open File...|^o'
  'Save|^s'
  'Save…|^s'
  'Save...|^s'
  'Downloads|^j'
  'Print…|^p'
  'Print...|^p'
  'Zoom In|^='
  'Zoom Out|^-'
)

case "${1:-apply}" in
  --list)
    for app in "${APPS[@]}"; do
      cur=$(defaults read "$app" NSUserKeyEquivalents 2>/dev/null) || continue
      printf '\n=== %s ===\n%s\n' "$app" "$cur"
    done
    ;;
  --reset)
    for app in "${APPS[@]}"; do
      defaults delete "$app" NSUserKeyEquivalents 2>/dev/null \
        && echo "cleared  $app"
    done
    echo
    echo "Relaunch the affected apps (or log out) for this to take effect."
    ;;
  apply)
    for app in "${APPS[@]}"; do
      for entry in "${BINDINGS[@]}"; do
        title=${entry%%|*}
        key=${entry##*|}
        defaults write "$app" NSUserKeyEquivalents -dict-add "$title" "$key"
      done
      echo "configured  $app"
    done
    echo
    echo "Done. Relaunch the affected apps (or log out and back in)."
    echo "Verify with: $0 --list"
    ;;
  *)
    echo "usage: $0 [--list|--reset]" >&2
    exit 64
    ;;
esac
