#!/usr/bin/env bash
#
# Switch between the two window managers, and keep them from ever running at
# once.
#
# They cannot coexist: AeroSpace and skhd both grab ⌘ combinations globally, so
# with both up every ⌘ chord is a race. skhd also hot-loads its config, which
# means ~/.config/skhd/skhdrc goes live the instant `make stow` creates the
# symlink -- while AeroSpace is still running. That is why the guard verbs
# exist and why the README says to run `wm.sh aerospace` before the first stow.
#
# The choice is written to ~/.config/dotfiles/wm and read back by the guards,
# which each manager calls on startup: AeroSpace from after-startup-command in
# aerospace.toml, yabai from the top of yabairc. AeroSpace has start-at-login in
# its own config and will come back after a reboot regardless of what we do
# here, so the guard is the only thing that actually keeps it down.
#
# Usage: wm.sh yabai | aerospace | status | guard-yabai | guard-aerospace

set -uo pipefail

YABAI=/opt/homebrew/bin/yabai
SKHD=/opt/homebrew/bin/skhd
MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/wm"

mkdir -p "$(dirname "$MARKER")"

choice() { [[ -r $MARKER ]] && cat "$MARKER" || echo aerospace; }

stop_aerospace() {
  # `aerospace enable off` only stops tiling -- it keeps the ⌘ grabs -- and
  # there is no `aerospace quit`. Quitting the app is the only thing that
  # actually releases the keys.
  osascript -e 'quit app "AeroSpace"' 2>/dev/null || pkill -x AeroSpace 2>/dev/null || true
  for _ in $(seq 30); do pgrep -x AeroSpace >/dev/null || break; sleep 0.1; done
}

case "${1:-status}" in
  yabai)
    stop_aerospace
    printf 'yabai' > "$MARKER"
    "$YABAI" --start-service
    "$SKHD" --start-service
    echo "switched to yabai + skhd"
    ;;

  aerospace)
    # --stop-service does launchctl bootout AND disable, so these stay down
    # across a reboot without any further help.
    "$SKHD" --stop-service 2>/dev/null || true
    "$YABAI" --stop-service 2>/dev/null || true
    printf 'aerospace' > "$MARKER"
    open -a AeroSpace
    echo "switched to AeroSpace"
    ;;

  status)
    printf 'configured: %s\n' "$(choice)"
    printf 'running:   '
    pgrep -x AeroSpace >/dev/null && printf ' AeroSpace'
    pgrep -x yabai     >/dev/null && printf ' yabai'
    pgrep -x skhd      >/dev/null && printf ' skhd'
    echo
    ;;

  # Called by each manager at startup. A no-op unless the OTHER one is the
  # configured choice, in which case this instance goes away again.
  guard-yabai)
    [[ $(choice) == yabai ]] || {
      "$SKHD" --stop-service 2>/dev/null || true
      "$YABAI" --stop-service 2>/dev/null || true
    }
    ;;
  guard-aerospace)
    [[ $(choice) == aerospace ]] || stop_aerospace
    ;;

  *)
    echo "usage: $0 [yabai|aerospace|status|guard-yabai|guard-aerospace]" >&2
    exit 64
    ;;
esac
