#!/usr/bin/env bash

set -uo pipefail

n=${1:-}
case "$n" in
  [1-9]) ;;
  *)
    echo "usage: $0 <1-9>" >&2
    exit 64
    ;;
esac

bundle=$(lsappinfo info -only bundleid "$(lsappinfo front)" 2>/dev/null |
  sed -n 's/.*"CFBundleIdentifier"="\(.*\)"/\1/p')

case "$bundle" in
  com.google.Chrome)
    app="Google Chrome"
    dialect=chromium
    ;;
  com.brave.Browser)
    app="Brave Browser"
    dialect=chromium
    ;;
  com.apple.Safari)
    app="Safari"
    dialect=safari
    ;;
  *) exit 0 ;; # not a browser we drive; leave the key alone
esac

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
