#!/usr/bin/env bash
#
# Select tab N in the frontmost browser.
#
# AeroSpace grabs cmd-1..9 for workspaces, so browsers lose their numbered tab
# shortcuts and there is no menu item to rebind -- Chrome's Tab menu only offers
# "Select Next/Previous Tab" plus the open tabs by page title, which change.
# Karabiner puts the jumps on opt-1..9 in browsers only and calls this script;
# see ../.config/karabiner/karabiner.json and docs/keybindings.md.
#
# Remapping opt-N to cmd-N would not work: AeroSpace's grab is global and
# catches synthesised cmd-N before the browser ever sees it.
#
# As in every browser, 1-8 pick that tab and 9 picks the last one, and a number
# past the end of the tab strip does nothing.
#
# Usage: ./browser-tab.sh <1-9>

set -uo pipefail

n=${1:-}
case "$n" in
  [1-9]) ;;
  *) echo "usage: $0 <1-9>" >&2; exit 64 ;;
esac

# ~10ms, versus ~100ms to ask System Events the same question.
bundle=$(lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null \
         | sed -n 's/.*"CFBundleIdentifier"="\(.*\)"/\1/p')

case "$bundle" in
  com.google.Chrome)  app="Google Chrome" ; dialect=chromium ;;
  com.brave.Browser)  app="Brave Browser" ; dialect=chromium ;;
  com.apple.Safari)   app="Safari"        ; dialect=safari   ;;
  *) exit 0 ;;   # not a browser we drive; leave the key alone
esac

# A browser can be frontmost with no window open at all -- do nothing, quietly.
# 9 means "last tab", so it is never bounds-checked; 1-8 do nothing past the end.
if [ "$dialect" = chromium ]; then
  if [ "$n" = 9 ]; then
    stmt='set active tab index to (count of tabs)'
  else
    stmt="if (count of tabs) >= $n then set active tab index to $n"
  fi
else
  if [ "$n" = 9 ]; then
    stmt='set current tab to last tab'
  else
    stmt="if (count of tabs) >= $n then set current tab to tab $n"
  fi
fi

exec osascript <<AS 2>/dev/null
tell application "$app"
  if (count of windows) > 0 then
    tell front window
      $stmt
    end tell
  end if
end tell
AS
