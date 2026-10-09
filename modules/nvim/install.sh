#!/usr/bin/env bash

set -euo pipefail

# sudo preserves EDITOR only when invoked as sudoedit.
target=/usr/bin/sudo
link="$HOME/.local/bin/sudoedit" # .zshrc puts ~/.local/bin on PATH

if [[ ! -x "$target" ]]; then
  echo "nvim: $target not found, skipping sudoedit link" >&2
  exit 0
fi

if [[ -L "$link" && "$(readlink "$link")" == "$target" ]]; then
  echo "nvim: sudoedit already linked"
  exit 0
fi

if [[ -e "$link" && ! -L "$link" ]]; then
  echo "nvim: $link exists and is not a symlink, leaving it alone" >&2
  exit 0
fi

mkdir -p "$(dirname "$link")"
ln -sfn "$target" "$link"
echo "nvim: linked $link -> $target"
