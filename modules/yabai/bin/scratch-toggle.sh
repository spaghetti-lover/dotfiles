#!/usr/bin/env bash
set -euo pipefail

yabai=/opt/homebrew/bin/yabai
jq=/opt/homebrew/bin/jq

if "$yabai" -m query --spaces --space | "$jq" -e '.label == "scratch"' >/dev/null; then
  "$yabai" -m space --focus recent
else
  "$yabai" -m space --focus scratch
fi
