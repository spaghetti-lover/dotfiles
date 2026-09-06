#!/usr/bin/env bash
#
# cmd-ctrl-k -- Omarchy's "browse all the Herdr bindings", ported from
# bin/omarchy-menu-herdr-keybindings. Omarchy draws it with walker; this uses
# fzf, the same substitution localsend-share.sh makes.
#
# herdr has no CLI that dumps resolved keybindings -- `herdr config` offers
# only check and reset-keys, and the in-app help is prefix+?, which is no use
# when herdr is not the window in front of you. So the action list and its
# defaults come from `herdr --default-config`, where every action appears as a
# commented `# action = "binding"` line, and the user's config.toml overrides
# those.
#
# Type to filter, esc closes. See docs/keybindings.md#herdr.

set -uo pipefail

HERDR=/opt/homebrew/bin/herdr
CONFIG="${HERDR_CONFIG_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml}"

die() { printf '\033[31m%s\033[0m\n' "$1" >&2; sleep 3; exit 1; }

[[ -x "$HERDR" ]] || die "herdr not found -- brew bundle install --file=install/Brewfile"
command -v fzf >/dev/null || die "fzf not found -- brew bundle install --file=install/Brewfile"

# With no config file, herdr runs on its own built-in defaults. Substituting a
# seed config here would describe bindings herdr never loaded.
[[ -f $CONFIG ]] || CONFIG=/dev/null

# SQ is the single quote. TOML literal strings are as valid as basic ones, so
# both quote characters open and close a value -- but naming the character
# rather than escaping it keeps this program free of shell-quoting traps.
read -r -d '' AWK_PROG <<'AWK' || true
BEGIN { SQ = sprintf("%c", 39) }

function strip_comment(value,   i, ch, quote, out) {
  quote = ""; out = ""
  for (i = 1; i <= length(value); i++) {
    ch = substr(value, i, 1)
    if (quote == "" && (ch == "\"" || ch == SQ)) quote = ch
    else if (ch == quote) quote = ""
    if (ch == "#" && quote == "") break
    out = out ch
  }
  return out
}

# Removes every quoted run, leaving only what surrounds the strings. An
# unterminated quote returns a sentinel no valid value can produce.
function without_quoted(value,   i, ch, quote, out) {
  quote = ""; out = ""
  for (i = 1; i <= length(value); i++) {
    ch = substr(value, i, 1)
    if (quote == "") {
      if (ch == "\"" || ch == SQ) quote = ch
      else out = out ch
    } else if (ch == quote) quote = ""
  }
  return quote == "" ? out : "\001"
}

# Prose in the default config can read like an assignment, as in
# `# type = "popup" opens a session-modal terminal`, so a value counts only
# when it is a bare string or an array of them.
function is_binding_value(value,   rest) {
  value = strip_comment(value)
  sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value)
  if (value == "") return 0
  rest = without_quoted(value)
  return rest == "" || rest ~ /^\[[[:space:],]*\]$/
}

function key_text(key,   count, parts, i, text) {
  count = split(key, parts, "+")
  text = ""
  for (i = 1; i <= count; i++) text = text (text == "" ? "" : " + ") toupper(parts[i])
  return text
}

# Renders every alternate binding for one action as "A / B".
function combo_text(value,   i, ch, quote, part, text) {
  value = strip_comment(value)
  quote = ""; part = ""; text = ""
  for (i = 1; i <= length(value); i++) {
    ch = substr(value, i, 1)
    if (quote == "") {
      if (ch == "\"" || ch == SQ) { quote = ch; part = "" }
      continue
    }
    if (ch == quote) {
      quote = ""
      if (part != "") text = text (text == "" ? "" : " / ") key_text(part)
      continue
    }
    part = part ch
  }
  return text
}

function describe(action,   text) {
  sub(/^navigate_/, "", action)
  gsub(/_/, " ", action)
  return toupper(substr(action, 1, 1)) substr(action, 2)
}

function remember(action) {
  if (action in seen) return
  seen[action] = 1
  order[++count] = action
}

function bind(action, value,   combo) {
  combo = combo_text(value)
  if (combo == "") return
  if (action ~ /^navigate_/) combo = "NAVIGATE + " combo
  remember(action)
  combos[action] = combo
}

# Pass 1: default config on stdin, for the action order and default bindings.
# Every line there is commented out, so section markers are too.
FNR == NR {
  line = $0
  sub(/^[[:space:]]*#[[:space:]]*/, "", line)
  if (line ~ /^\[\[keys\.command\]\]/) { in_keys = 0; next }
  if (line ~ /^\[/) { in_keys = (line ~ /^\[keys\]/); next }
  if (!in_keys) next
  if (line !~ /^[a-z_]+[[:space:]]*=/) next

  action = line; sub(/[[:space:]]*=.*$/, "", action)
  value = line;  sub(/^[^=]*=[[:space:]]*/, "", value)
  if (!is_binding_value(value)) next

  # Actions herdr leaves unbound still hold their place in the listing order,
  # for when the user config binds them.
  remember(action)
  bind(action, value)
  next
}

# Pass 2: the user config, which overrides the defaults it sets.
{
  if ($0 ~ /^\[\[keys\.command\]\]/) { in_user_keys = 0; next }
  if ($0 ~ /^\[/) { in_user_keys = ($0 ~ /^\[keys\]/); next }
  if (!in_user_keys) next
  if ($0 ~ /^[[:space:]]*#/) next
  if ($0 !~ /^[[:space:]]*[a-z_]+[[:space:]]*=/) next

  line = $0; sub(/^[[:space:]]*/, "", line)
  action = line; sub(/[[:space:]]*=.*$/, "", action)
  value = line;  sub(/^[^=]*=[[:space:]]*/, "", value)
  if (!is_binding_value(value)) next

  # An action bound to nothing in the user config is unbound, not defaulted.
  if (combo_text(value) == "") { delete combos[action]; next }
  bind(action, value)
}

END {
  if ("prefix" in combos) printf "%-32s → %s\n", "PREFIX", combos["prefix"]
  for (i = 1; i <= count; i++) {
    action = order[i]
    if (action == "prefix" || !(action in combos)) continue
    printf "%-32s → %s\n", combos[action], describe(action)
  }
}
AWK

records=$("$HERDR" --default-config | awk "$AWK_PROG" - "$CONFIG")
[[ -n "$records" ]] || die "could not read any keybindings from herdr --default-config"

printf '%s\n' "$records" |
  fzf --prompt='> ' --header=$'Herdr keybindings\n' --header-first \
      --reverse --no-info --pointer='>' --color='gutter:-1' >/dev/null || true
