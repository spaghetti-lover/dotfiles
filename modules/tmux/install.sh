#!/usr/bin/env bash
set -euo pipefail

plugin_manager="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$plugin_manager" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$plugin_manager"
fi

echo 'Tmux plugins: reload with prefix + q, then install with prefix + I.'
