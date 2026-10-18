#!/usr/bin/env bash
set -euo pipefail

mode="${1:---install}"
case "$mode" in
  --install | --check | --print) ;;
  *)
    echo "Usage: $0 [--install|--check|--print] [module...]" >&2
    exit 2
    ;;
esac
shift $(($# ? 1 : 0))

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
select_modules "$@"

# Build one Brewfile from every module; taps go first so their formulae resolve.
brewfile() {
  local kind module name
  for kind in tap brew cask go cargo; do
    [[ "$kind" == cask && "$platform" != macos ]] && continue
    for module in "${modules[@]}"; do
      while IFS= read -r name; do
        printf '%s "%s"\n' "$kind" "$name"
      done < <(module_entries "$module" "$kind")
    done
  done | awk '!seen[$0]++'
}

if [[ "$mode" == --print ]]; then
  brewfile
  exit 0
fi

command -v brew >/dev/null || {
  echo "Install Homebrew first: https://brew.sh" >&2
  exit 1
}

file="$(mktemp -t dotfiles-brewfile.XXXXXX)"
trap 'rm -f "$file"' EXIT
brewfile >"$file"
if [[ "$mode" == --check ]]; then
  brew bundle check --verbose --file="$file"
else
  brew bundle install --file="$file"
fi
