#!/usr/bin/env bash
set -euo pipefail

# settings.json holds per-machine state, so point it at the status line in place.
settings="$HOME/.claude/settings.json"
mkdir -p "$(dirname "$settings")"
[[ -f "$settings" ]] || echo '{}' >"$settings"
tmp="$(mktemp)"
jq '.statusLine = {type: "command", command: "bash ~/.claude/statusline.sh"}' "$settings" >"$tmp"
cat "$tmp" >"$settings"
rm "$tmp"
