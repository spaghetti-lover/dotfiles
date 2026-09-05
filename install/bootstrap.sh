#!/usr/bin/env bash
#
# Full machine setup. Idempotent -- safe to re-run at any time.
#
#   1. install everything in install/Brewfile
#   2. symlink every module in modules/ into $HOME
#   3. run each module's install.sh, if it has one
#
# Usage: make install   (or: bash install/bootstrap.sh)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

step() { printf '\n\033[36m==> %s\033[0m\n' "$1"; }

step "Installing packages from install/Brewfile"
if command -v brew >/dev/null 2>&1; then
  brew bundle install --file=install/Brewfile
else
  echo "brew not found -- install Homebrew first: https://brew.sh" >&2
  exit 1
fi

step "Stowing modules into $HOME"
make stow

step "Running module install hooks"
ran_any=false
for hook in modules/*/install.sh; do
  [[ -x "$hook" ]] || continue
  ran_any=true
  echo "--> $hook"
  "$hook"
done
$ran_any || echo "(no module defines an install.sh yet)"

step "Done"
cat <<'NEXT'
Two things still need a human:

  make macos-shortcuts   Restore the macOS menu commands AeroSpace displaces.
                         Not optional -- Cmd-S is the scratchpad toggle, so
                         Save has nowhere else to go.

  Karabiner-Elements     Launch it once and grant Input Monitoring, so Alt+1-9
                         reaches your browser tabs.
NEXT
