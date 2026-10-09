#!/usr/bin/env bash
set -euo pipefail

# Karabiner rewrites its config, so merge rules instead of linking it.
rules_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/share/karabiner.json"
config_path="${XDG_CONFIG_HOME:-$HOME/.config}/karabiner/karabiner.json"
mkdir -p "$(dirname "$config_path")"

temp_path="$(mktemp "${config_path}.XXXXXX")"
trap 'rm -f "$temp_path"' EXIT

if [[ -f "$config_path" ]]; then
  /opt/homebrew/bin/jq --slurpfile managed "$rules_path" '
    .profiles |= map(
      if .selected == true then
        .complex_modifications.rules = (
          $managed[0].profiles[0].complex_modifications.rules
          + ((.complex_modifications.rules // []) | map(select(
              (.description // "") as $description
              | $description != "Use Control as Command in Google Chrome"
                and $description != "Use Control as Command for Chrome clicks, keep keyboard chords"
                and $description != "Omarchy Super window shortcuts (Command stays Super)"
                and $description != "Linux Chrome tab shortcuts on Control"
                and $description != "Linux app shortcuts on Control in macOS GUI apps"
            )))
        )
      else . end
    )
  ' "$config_path" >"$temp_path"
else
  cp "$rules_path" "$temp_path"
fi

chmod 600 "$temp_path"
mv -f "$temp_path" "$config_path"
trap - EXIT

if launchctl list | /usr/bin/grep -q 'org.pqrs.service.agent.Karabiner-Console-User-Server'; then
  launchctl kickstart -k "gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server"
fi

printf 'Installed Omarchy Karabiner rules in %s\n' "$config_path"
