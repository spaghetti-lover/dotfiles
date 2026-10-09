#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

case "$(uname -s)" in
  Darwin)
    command -v brew >/dev/null || {
      echo "Install Homebrew first: https://brew.sh" >&2
      exit 1
    }
    brew bundle install --file=install/Brewfile
    bash install/link.sh --apply
    for hook in modules/*/install.sh; do
      bash "$hook"
    done
    ;;
  Linux)
    command -v omarchy >/dev/null || {
      echo "Linux setup requires Omarchy" >&2
      exit 1
    }
    bash install/link.sh --apply
    ;;
  *)
    echo "Unsupported OS" >&2
    exit 1
    ;;
esac
