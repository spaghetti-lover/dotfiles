#!/usr/bin/env bash
set -euo pipefail

mode="${1:---dry-run}"
case "$mode" in
  --dry-run | --apply | --unlink) ;;
  *)
    echo "Usage: $0 [--dry-run|--apply|--unlink]" >&2
    exit 2
    ;;
esac

case "$(uname -s)" in
  Darwin) platform=macos ;;
  Linux) platform=omarchy ;;
  *)
    echo "Unsupported OS" >&2
    exit 1
    ;;
esac

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
backup=""

links() { cat "$repo/install/links/common" "$repo/install/links/$platform"; }

# Expand old Stow directory links before editing their children.
unfold_parents() {
  local parent="$1" target child
  [[ "$parent" == "$HOME" || "$parent" == / ]] && return 0
  unfold_parents "$(dirname "$parent")"
  [[ -L "$parent" && -d "$parent" ]] || return 0
  target="$(cd "$parent" && pwd -P)"
  case "$target" in
    "$repo"/*)
      echo "unfold: $parent"
      if [[ "$mode" != --dry-run ]]; then
        rm "$parent"
        mkdir "$parent"
        for child in "$target"/* "$target"/.[!.]* "$target"/..?*; do
          [[ -e "$child" || -L "$child" ]] || continue
          ln -s "$child" "$parent/$(basename "$child")"
        done
      fi
      ;;
  esac
}

# Validate every source before changing any destination.
while IFS='|' read -r source destination; do
  [[ -n "$source" ]] || continue
  case "/$destination/" in
    / | //* | */../* | */./*)
      echo "Invalid home destination: $destination" >&2
      exit 1
      ;;
  esac
  [[ "$source" == . ]] && source="$repo" || source="$repo/$source"
  destination="$HOME/$destination"
  if [[ "$mode" != --unlink && ! -e "$source" ]]; then
    echo "Missing source: $source" >&2
    exit 1
  fi
  [[ "$destination" -ef "$source" ]] && continue
  if [[ "$mode" != --unlink && -d "$destination" && ! -L "$destination" ]]; then
    resolved="$(cd "$destination" && pwd -P)"
    case "$repo/" in
      "$resolved/"*)
        echo "Refusing to replace checkout's parent: $destination" >&2
        exit 1
        ;;
    esac
  fi
done < <(links)

while IFS='|' read -r source destination; do
  [[ -n "$source" ]] || continue
  [[ "$source" == . ]] && source="$repo" || source="$repo/$source"
  destination="$HOME/$destination"
  unfold_parents "$(dirname "$destination")"

  if [[ "$mode" == --unlink ]]; then
    if [[ -L "$destination" ]] && { [[ "$destination" -ef "$source" ]] || [[ "$(readlink "$destination")" == "$source" ]]; }; then
      echo "unlink: $destination"
      rm "$destination"
    fi
    continue
  fi

  if [[ "$destination" -ef "$source" ]]; then
    echo "ready: $destination"
    continue
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    echo "backup: $destination"
    if [[ "$mode" == --apply ]]; then
      if [[ -z "$backup" ]]; then
        backup_base="$HOME/.local/state/dotfiles-backups"
        mkdir -p "$backup_base"
        backup="$(mktemp -d "$backup_base/$(date +%Y%m%d-%H%M%S).XXXXXX")"
      fi
      relative="${destination#"$HOME"/}"
      mkdir -p "$backup/$(dirname "$relative")"
      mv "$destination" "$backup/$relative"
    fi
  fi

  echo "link: $destination -> $source"
  if [[ "$mode" == --apply ]]; then
    mkdir -p "$(dirname "$destination")"
    ln -s "$source" "$destination"
  fi
done < <(links)

if [[ -n "$backup" ]]; then echo "Backups: $backup"; fi
