#!/usr/bin/env bash
#
# Restore the macOS menu commands that AeroSpace's Omarchy bindings take over.
#
# AeroSpace grabs cmd-* globally (see aerospace/.config/aerospace/aerospace.toml),
# so cmd-O, cmd-G, cmd-S, cmd-P, cmd-shift-D and cmd-+/- never reach an app.
# (cmd-F is not among them any more -- nothing is bound to it, so Find works
# natively.)
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
# A global write would steal those inside Ghostty, so terminal bundle IDs are
# deliberately absent from APPS below.
#
# Back / Forward move to alt-arrow (the Linux convention) because cmd-left and
# cmd-right are AeroSpace's focus keys. Arrow keys in NSUserKeyEquivalents are
# the AppKit function-key constants, not the U+2190 glyphs: NSLeftArrow is
# U+F702 and NSRightArrow U+F703. This binds at the menu layer, so it fires
# ahead of the text field -- alt-arrow no longer moves the caret a word at a
# time inside these apps.
#
# Search Tabs moves to ctrl-shift-A, because cmd-shift-A is the ChatGPT launcher.
# Shift is not optional: plain ctrl-A is beginning-of-line in every text field.
#
# Bookmark All Tabs and Finder's Go > Desktop move to ctrl-shift-D for the same
# reason: cmd-shift-D is the lazydocker launcher. Shift again is not optional --
# plain ctrl-D is end-of-file.

# Find Previous moves to ctrl-shift-G for a different reason: AeroSpace never
# grabs cmd-shift-G, but every AppKit app binds it to Find Previous, which makes
# it unavailable as an app's own global hotkey (Gemini refuses it with "already
# used for Find Previous"). Rebinding frees it, and keeps Find Next / Previous
# symmetric on ctrl-G / ctrl-shift-G.
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
  com.openai.codex                                       # ChatGPT.app
  com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep # Google Calendar web app
  com.google.Chrome.app.mnhkaebcjjhencmpkapnbdaogjamfbcj # Google Maps web app
  com.microsoft.VSCode
  com.apple.dt.Xcode
  com.apple.Pages
  com.apple.Numbers
  com.apple.Keynote
  com.apple.iMovieApp
  com.apple.garageband10
  com.obsproject.obs-studio
  org.localsend.localsendApp                             # LocalSend (Flutter; most titles no-op)
)

# "Menu item title|shortcut". Titles must match the menu bar EXACTLY, so the
# ellipsis items are written twice: once with U+2026 and once with three
# periods, since apps are inconsistent. Writing a title an app does not have
# is a harmless no-op.
# NSLeftArrowFunctionKey (U+F702) and NSRightArrowFunctionKey (U+F703), as
# raw UTF-8 octal -- macOS ships bash 3.2, which has no $'\uXXXX' escape and
# would silently write the literal text "uF702" instead.
ARROW_LEFT=$(printf '\357\234\202')
ARROW_RIGHT=$(printf '\357\234\203')

BINDINGS=(
  'Find Next|^g'
  'Find Previous|^$g'
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
  'Search Tabs…|^$a'
  'Search Tabs...|^$a'
  'Search Tabs|^$a'
  'Bookmark All Tabs…|^$d'
  'Bookmark All Tabs...|^$d'
  'Desktop|^$d'
  "Back|~${ARROW_LEFT}"
  "Forward|~${ARROW_RIGHT}"
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
