#!/usr/bin/env bash
#
# Authorise `yabai --load-sa` to run without a password prompt.
#
# yabai injects a scripting addition into Dock.app, which owns the sole
# connection to the window server. Everything to do with spaces goes through it:
# space --focus / --create / --destroy / --display, window --space, sticky
# windows, --sub-layer. That is ⌘1..9, ⌘⇧1..9 and ⌘O -- without this, most of
# skhdrc silently does nothing.
#
# The sudoers rule is pinned to a hash of the yabai binary, so it MUST be re-run
# after every `brew upgrade yabai`, or the scripting addition stops loading with
# no error anywhere. Run it after a macOS update too: the addition is unloaded
# by the update and yabairc's dock_did_restart signal is what puts it back.
#
# Requires System Integrity Protection to be partially disabled:
#   csrutil enable --without fs --without debug --without nvram   (recovery mode)
#
# AND, on Apple Silicon, an NVRAM boot-arg that permits non-Apple-signed arm64e
# binaries. Without it yabai loads but every space command fails with
# "missing required nvram boot-arg '-arm64e_preview_abi'":
#   sudo nvram boot-args=-arm64e_preview_abi                      (then reboot)
#
# Usage: sudo-free -- it calls sudo itself and will prompt once.

set -euo pipefail

yabai=$(command -v yabai) || { echo "yabai not found -- brew bundle install --file=install/Brewfile" >&2; exit 1; }

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

# Apple Silicon only, and easy to miss because yabai starts fine without it --
# it is only the scripting addition that fails, and it fails per command.
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

# visudo -c catches a malformed rule before it locks sudo up.
sudo visudo -c -f /private/etc/sudoers.d/yabai

sudo yabai --load-sa && echo "scripting addition loaded"
