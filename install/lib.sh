# Shared by the install scripts. Each modules/<name>/module.conf holds one
# entry per line: `<kind>[@macos|@omarchy] <value>`, see README.md.

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
platforms=(macos omarchy)
kinds=(platforms link tap brew cask go cargo)

case "$(uname -s)" in
  Darwin) platform=macos ;;
  Linux) platform=omarchy ;;
  *)
    echo "Unsupported OS" >&2
    exit 1
    ;;
esac

# Print a module's values for <kind>, including entries scoped to this platform.
module_entries() {
  local module="$1" kind="$2" key value
  while read -r key value; do
    case "$key" in
      "$kind" | "$kind@$platform") printf '%s\n' "$value" ;;
    esac
  done < <(grep -v '^[[:space:]]*\(#\|$\)' "$repo/modules/$module/module.conf")
}

# Fail on a typo in a manifest rather than silently skipping the entry.
check_module() {
  local module="$1" conf="$repo/modules/$1/module.conf" key value scope
  [[ -f "$conf" ]] || {
    echo "Unknown module: $module (no $conf)" >&2
    exit 1
  }
  while read -r key value; do
    scope="${key#*@}"
    [[ "$key" == *@* ]] || scope=
    if [[ " ${kinds[*]} " != *" ${key%@*} "* || ( -n "$scope" && " ${platforms[*]} " != *" $scope "* ) || -z "$value" ]]; then
      echo "$conf: invalid entry: $key $value" >&2
      exit 1
    fi
  done < <(grep -v '^[[:space:]]*\(#\|$\)' "$conf")
}

# Modules without a `platforms` entry run everywhere.
module_enabled() {
  local allowed
  allowed="$(module_entries "$1" platforms)"
  [[ -z "$allowed" || " $(echo $allowed) " == *" $platform "* ]]
}

# Set `modules` to the named modules (default: all) that run on this platform.
select_modules() {
  local module dir names=("$@")
  if ((${#names[@]} == 0)); then
    for dir in "$repo"/modules/*/; do
      names+=("$(basename "$dir")")
    done
  fi
  modules=()
  for module in "${names[@]}"; do
    check_module "$module"
    if module_enabled "$module"; then
      modules+=("$module")
    elif (($#)); then
      echo "skip: $module (not for $platform)" >&2
    fi
  done
}
