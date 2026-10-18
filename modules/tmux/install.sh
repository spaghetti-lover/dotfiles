#!/usr/bin/env bash
set -euo pipefail

plugin_manager="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$plugin_manager" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$plugin_manager"
fi

"$plugin_manager/bin/install_plugins"

echo 'Tmux plugins installed; reload a running server with prefix + q.'
