#!/usr/bin/env bash
#
# Give macOS a sudoedit.
#
# Linux ships /usr/bin/sudoedit as a link to sudo; macOS ships only sudo. That
# matters because sudo picks its mode from the name it was invoked under, and
# sudoers(5) is explicit about the consequence:
#
#   "Unless invoked as sudoedit, sudo does not preserve the SUDO_EDITOR, VISUAL
#    or EDITOR environment variables unless they are present in the env_keep
#    list or the env_reset option is disabled."
#
# So `sudo -e` is NOT the same thing: env_reset strips EDITOR, sudo falls back
# to the sudoers `editor` list, and you land in /usr/bin/vi with no config.
# Invoked through a link named sudoedit, EDITOR survives and you get nvim with
# the full plugin set. Spoofing argv[0] does not work -- sudo resolves its own
# executable path rather than trusting it -- so this has to be a real link.
#
# This is not stowed: stow aborts outright on an absolute symlink inside a
# package, and a relative one would have to climb out of the repo with a fixed
# number of ../ that breaks the moment the repo moves.
#
# Run by install/bootstrap.sh (make install). Idempotent.

set -euo pipefail

target=/usr/bin/sudo
link="$HOME/.local/bin/sudoedit"   # .zshrc puts ~/.local/bin on PATH

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
