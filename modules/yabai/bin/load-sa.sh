#!/usr/bin/env bash

set -euo pipefail

yabai=$(command -v yabai) || {
  echo "yabai not found -- brew bundle install --file=install/Brewfile" >&2
  exit 1
}

if csrutil status 2>/dev/null | grep -q "status: enabled"; then
  cat >&2 <<'WARN'
System Integrity Protection is fully enabled.

The scripting addition cannot load, so spaces, sticky windows and window layers
will not work -- floating TUIs still will. To enable them, boot into recovery
(hold the power button -> Options -> Utilities -> Terminal) and run:

    csrutil enable --without fs --without debug --without nvram

then reboot and run this script again.
WARN
  exit 1
fi

if [[ $(uname -m) == arm64 ]] && ! nvram boot-args 2>/dev/null | grep -q -- '-arm64e_preview_abi'; then
  cat >&2 <<'WARN'
The '-arm64e_preview_abi' boot-arg is not set.

yabai will run, but the scripting addition cannot load into Dock.app, so spaces,
sticky windows and window layers stay broken. Set it and reboot:

    sudo nvram boot-args=-arm64e_preview_abi

then run this script again. (To undo later: sudo nvram -d boot-args)
WARN
  exit 1
fi

hash=$(shasum -a 256 "$yabai" | cut -d' ' -f1)
rule="$(whoami) ALL=(root) NOPASSWD: sha256:${hash} ${yabai} --load-sa"

printf '%s\n' "$rule" | sudo tee /private/etc/sudoers.d/yabai >/dev/null
sudo chmod 0440 /private/etc/sudoers.d/yabai

sudo visudo -c -f /private/etc/sudoers.d/yabai

sudo yabai --load-sa && echo "scripting addition loaded"
