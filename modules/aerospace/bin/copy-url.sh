#!/usr/bin/env bash
#
# Omarchy's Shift+Alt+L: copy the URL of the page you are looking at.
#
# A web app (Chrome > Cast, save and share > Install page as app) has no address
# bar, so there is no cmd-L to copy from. This asks Chrome for the URL instead
# and puts it on the clipboard.
#
# AeroSpace grabs alt-shift-l globally, so this runs from every app -- hence the
# focused-app check: anything that is not Chrome, Brave or a Chrome web app
# exits 0 without touching the clipboard.
#
# The focused app comes from AeroSpace itself, not System Events or lsappinfo:
# AeroSpace is the thing that just ran us and it knows which window has focus,
# so no Accessibility grant is needed. (lsappinfo is no help here -- it reports
# AeroSpace as the front application.) Reading the URL still needs an Automation
# grant, "AeroSpace wants to control Google Chrome", asked for once on first use.
#
# A web app window is an ordinary Chrome `Browser` object living in the browser
# process -- only its frame is drawn by the app shim -- so Chrome's `front
# window` is the web app's window while the shim is focused.

set -uo pipefail

bundle=$(aerospace list-windows --focused --format '%{app-bundle-id}' 2>/dev/null) || exit 0

# com.google.Chrome.app.* is the shim of an installed web app -- one bundle id
# per app, so match the prefix rather than listing them.
case "$bundle" in
  com.google.Chrome|com.google.Chrome.*) app='Google Chrome' ;;
  *)                                     exit 0 ;;
esac

url=$(osascript -e "tell application \"$app\" to get URL of active tab of front window" 2>/dev/null) || exit 0
[[ -n $url ]] || exit 0

printf '%s' "$url" | pbcopy
