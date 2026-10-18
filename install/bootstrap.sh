#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

source install/lib.sh
if [[ "$platform" == omarchy ]] && ! command -v omarchy >/dev/null; then
  echo "Linux setup requires Omarchy" >&2
  exit 1
fi
select_modules "$@"
((${#modules[@]})) || exit 0

# One package failing shouldn't block linking configs; report it at the end.
failed=()
bash install/packages.sh --install "${modules[@]}" || failed+=(packages)
bash install/link.sh --apply "${modules[@]}"
for module in "${modules[@]}"; do
  if [[ -f "modules/$module/install.sh" ]]; then
    echo "hook: $module"
    bash "modules/$module/install.sh" || failed+=("$module hook")
  fi
done

if ((${#failed[@]})); then
  printf 'Failed: %s\n' "${failed[@]}" >&2
  exit 1
fi
