#!/usr/bin/env bash
set -euo pipefail

command -v herdr >/dev/null || exit 0
plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/agent-numbers" && pwd -P)"
herdr plugin link "$plugin_dir"
