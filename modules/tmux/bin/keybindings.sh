#!/usr/bin/env bash
set -euo pipefail

if command -v omarchy-menu-tmux-keybindings >/dev/null 2>&1; then
  omarchy-menu-tmux-keybindings --print
else
  tmux list-keys -N
fi
