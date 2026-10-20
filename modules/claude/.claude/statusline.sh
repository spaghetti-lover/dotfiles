#!/bin/bash
# Claude Code status line - four-line layout:
#   1: 🤖 model  ⚡effort  💡thinking  | 🎨 output style
#   2: 📁 cwd  🌿 (branch)  | 💰 session cost  | ⏱ session duration
#   3: 📝 Context   [40-block gradient bar]  N% used (tokens/window)
#   4: 🚀 Usage 5H  [10-block bar]  N% (4h35m left) │ 7D  [10-block bar]  N% (Wed 15:47)
#
# The 5h window shows a relative countdown (it's short); the 7d window shows an
# absolute weekday+time, falling back to a countdown when it's under a day out.
# Every row is independent - rows whose data is absent are simply not emitted,
# so API-key/Bedrock/Vertex sessions (no `rate_limits`) degrade to lines 1-3.
#
# Catppuccin gradient palette and the bar math are adapted from Awesome
# Statusline's `medium` preset (github.com/AwesomeJun/CC-statusline, MIT).

input=$(cat)

# One jq call for everything (this runs on every render, so keep it to one).
fields=$(echo "$input" | jq -r '[
  .model.display_name,
  .effort.level,
  .thinking.enabled,
  .output_style.name,
  .workspace.current_dir,
  .cost.total_cost_usd,
  .cost.total_duration_ms,
  .context_window.total_input_tokens,
  .context_window.context_window_size,
  .context_window.used_percentage,
  .rate_limits.five_hour.used_percentage,
  .rate_limits.five_hour.resets_at,
  .rate_limits.seven_day.used_percentage,
  .rate_limits.seven_day.resets_at
] | map(if . == null then "" else (.|tostring) end) | .[]')

# One field per line. Note: `@tsv` + `read` does NOT work here - tab is a
# whitespace IFS, so `read` collapses runs of empty fields and shifts every
# later value into the wrong variable as soon as one field is absent.
{
  IFS= read -r model
  IFS= read -r effort
  IFS= read -r thinking
  IFS= read -r output_style
  IFS= read -r cwd
  IFS= read -r cost
  IFS= read -r duration_ms
  IFS= read -r tokens
  IFS= read -r window_size
  IFS= read -r used_pct
  IFS= read -r five_hour
  IFS= read -r five_hour_resets
  IFS= read -r seven_day
  IFS= read -r seven_day_resets
} <<< "$fields"

# ---------------------------------------------------------------- palette ---
E=$'\033'
RESET="${E}[0m"
BOLD="${E}[1m"
PINK="${E}[38;2;245;194;231m"
LAVENDER="${E}[38;2;180;190;254m"
YELLOW="${E}[38;2;249;226;175m"
GREEN="${E}[38;2;64;160;43m"
SUBTEXT="${E}[38;2;166;173;200m"
OVERLAY="${E}[38;2;108;112;134m"

# --------------------------------------------------------------- gradients ---
# Each sets $GRAD to "r;g;b" rather than echoing, so bar rendering costs no
# subshells - 60 blocks per render would otherwise be 60 forks.
GRAD=""

grad_context() {  # yellow -> red (50%) -> mauve (100%)
  local pct=$1 t
  if [ "$pct" -lt 50 ]; then
    t=$(( pct * 2 ))
    GRAD="$(( 223 + (210 - 223) * t / 100 ));$(( 142 + (15 - 142) * t / 100 ));$(( 29 + (57 - 29) * t / 100 ))"
  else
    t=$(( (pct - 50) * 2 ))
    GRAD="$(( 210 + (136 - 210) * t / 100 ));$(( 15 + (57 - 15) * t / 100 ));$(( 57 + (239 - 57) * t / 100 ))"
  fi
}

grad_usage() {  # green -> teal (50%) -> blue (100%); shared by 5H and 7D
  local pct=$1 t
  if [ "$pct" -lt 50 ]; then
    t=$(( pct * 2 ))
    GRAD="$(( 166 + (23 - 166) * t / 100 ));$(( 227 + (146 - 227) * t / 100 ));$(( 161 + (153 - 161) * t / 100 ))"
  else
    t=$(( (pct - 50) * 2 ))
    GRAD="$(( 23 + (30 - 23) * t / 100 ));$(( 146 + (102 - 146) * t / 100 ));$(( 153 + (245 - 153) * t / 100 ))"
  fi
}

BAR=""
END_COLOR=""
make_bar() {
  # make_bar <pct> <width> <grad fn>; sets $BAR (each filled block carries the
  # gradient at its own position) and $END_COLOR (the value's own color).
  local pct=$1 width=$2 fn=$3 filled i
  [ "$pct" -lt 0 ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( (pct * width + 50) / 100 ))
  [ "$filled" -gt "$width" ] && filled=$width

  "$fn" "$pct"; END_COLOR="$GRAD"

  BAR=""
  for ((i = 0; i < filled; i++)); do
    "$fn" $(( i * 100 / width ))
    BAR="${BAR}${E}[38;2;${GRAD}m█"
  done
  for ((i = filled; i < width; i++)); do
    BAR="${BAR}${E}[38;2;${END_COLOR}m░"
  done
  BAR="${BAR}${RESET}"
}

# ------------------------------------------------------------------ times ---
now_epoch=$(date +%s)

fmt_relative() {  # -> "4h35m" / "35m" / "<1m" / "now"
  local diff=$(( $1 - now_epoch )) h m
  if [ "$diff" -le 0 ]; then echo "now"
  elif [ "$diff" -lt 60 ]; then echo "<1m"
  else
    h=$(( diff / 3600 )); m=$(( (diff % 3600) / 60 ))
    if [ "$h" -ge 1 ]; then printf "%dh%02dm" "$h" "$m"; else printf "%dm" "$m"; fi
  fi
}

countdown() {  # -> "4h35m left" / "resetting now"
  local rel; rel=$(fmt_relative "$1")
  if [ "$rel" = "now" ]; then echo "resetting now"; else echo "${rel} left"; fi
}

fmt_absolute() {  # -> "Wed 15:47"; macOS BSD date first, GNU date as fallback
  local epoch="$1" out
  out=$(LC_TIME=C date -j -f %s "$epoch" "+%a %H:%M" 2>/dev/null) && [ -n "$out" ] && { echo "$out"; return; }
  out=$(LC_TIME=C date -r "$epoch" "+%a %H:%M" 2>/dev/null) && [ -n "$out" ] && { echo "$out"; return; }
  LC_TIME=C date -d "@$epoch" "+%a %H:%M" 2>/dev/null
}

# ----------------------------------------------------------------- branch ---
git_branch() {
  # Read .git/HEAD directly by walking up from $cwd - no `git` subprocess, so
  # this stays cheap enough to run on every render. Handles worktrees, where
  # .git is a file containing "gitdir: <path>".
  local dir="$1" gitdir head
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then gitdir="$dir/.git"; break; fi
    if [ -f "$dir/.git" ]; then
      gitdir=$(sed -n 's/^gitdir: //p' "$dir/.git" 2>/dev/null)
      case "$gitdir" in /*) ;; *) gitdir="$dir/$gitdir" ;; esac
      break
    fi
    dir="${dir%/*}"
  done
  [ -n "$gitdir" ] && [ -r "$gitdir/HEAD" ] || return
  head=$(<"$gitdir/HEAD")
  case "$head" in
    ref:*) echo "${head#ref: refs/heads/}" ;;   # keeps slashes: feature/foo
    *)     echo "${head:0:7}" ;;                # detached: short sha
  esac
}

# ------------------------------------------------------------------ lines ---
lines=()

# Line 1: model, effort, thinking, output style
line1="🤖 ${BOLD}${PINK}${model}${RESET}"
[ -n "$effort" ] && line1="${line1} ${LAVENDER}⚡${effort}${RESET}"
[ "$thinking" = "true" ] && line1="${line1} 💡"
[ -n "$output_style" ] && [ "$output_style" != "null" ] && \
  line1="${line1} ${OVERLAY}│${RESET} 🎨 ${SUBTEXT}${output_style}${RESET}"
lines+=("$line1")

# Line 2: cwd, branch, cost, duration
line2=""
if [ -n "$cwd" ]; then
  TILDE='~'
  line2="📁 ${SUBTEXT}${cwd/#$HOME/$TILDE}${RESET}"
  branch=$(git_branch "$cwd")
  [ -n "$branch" ] && line2="${line2} ${GREEN}🌿 (${branch})${RESET}"
fi
if [ -n "$cost" ]; then
  [ -n "$line2" ] && line2="${line2} ${OVERLAY}│${RESET} "
  line2="${line2}💰 ${YELLOW}$(printf '%.2f' "$cost")\$${RESET}"
fi
if [ -n "$duration_ms" ] && [ "$duration_ms" -gt 0 ] 2>/dev/null; then
  secs=$(( duration_ms / 1000 ))
  if   [ "$secs" -ge 3600 ]; then dur="$(( secs / 3600 ))h$(( secs % 3600 / 60 ))m"
  elif [ "$secs" -ge 60 ];   then dur="$(( secs / 60 ))m"
  else                            dur="${secs}s"; fi
  [ -n "$line2" ] && line2="${line2} ${OVERLAY}│${RESET} "
  line2="${line2}⏱ ${SUBTEXT}${dur}${RESET}"
fi
[ -n "$line2" ] && lines+=("$line2")

round_pct() {  # clamp a float percentage to an int 0-100
  local p; p=$(printf '%.0f' "$1")
  [ "$p" -lt 0 ] && p=0
  [ "$p" -gt 100 ] && p=100
  echo "$p"
}

# Line 3: context, on its own row with the wide bar
if [ -n "$tokens" ] && [ -n "$used_pct" ]; then
  pct=$(round_pct "$used_pct")
  make_bar "$pct" 40 grad_context
  row="📝 ${E}[38;2;${END_COLOR}mContext${RESET} ${BAR} ${E}[38;2;${END_COLOR}m${pct}% used${RESET}"
  if [ -n "$window_size" ] && [ "$window_size" -gt 0 ] 2>/dev/null; then
    row="${row} ${SUBTEXT}($(( tokens / 1000 ))k/$(( window_size / 1000 ))k)${RESET}"
  fi
  lines+=("$row")
fi

# Line 4: both usage windows share one row, with narrow bars
usage_row=""
if [ -n "$five_hour" ]; then
  pct=$(round_pct "$five_hour")
  make_bar "$pct" 10 grad_usage
  usage_row="🚀 ${E}[38;2;${END_COLOR}mUsage 5H${RESET} ${BAR} ${E}[38;2;${END_COLOR}m${pct}%${RESET}"
  [ -n "$five_hour_resets" ] && \
    usage_row="${usage_row} ${OVERLAY}($(countdown "$five_hour_resets"))${RESET}"
fi
if [ -n "$seven_day" ]; then
  pct=$(round_pct "$seven_day")
  make_bar "$pct" 10 grad_usage
  if [ -n "$usage_row" ]; then
    usage_row="${usage_row} ${OVERLAY}│${RESET} ${E}[38;2;${END_COLOR}m7D${RESET}"
  else
    usage_row="🚀 ${E}[38;2;${END_COLOR}mUsage 7D${RESET}"
  fi
  usage_row="${usage_row} ${BAR} ${E}[38;2;${END_COLOR}m${pct}%${RESET}"
  if [ -n "$seven_day_resets" ]; then
    if [ $(( seven_day_resets - now_epoch )) -lt 86400 ]; then
      usage_row="${usage_row} ${OVERLAY}($(countdown "$seven_day_resets"))${RESET}"
    else
      usage_row="${usage_row} ${OVERLAY}($(fmt_absolute "$seven_day_resets"))${RESET}"
    fi
  fi
fi
[ -n "$usage_row" ] && lines+=("$usage_row")

# Join with newlines, no trailing newline.
out=""
for i in "${!lines[@]}"; do
  [ "$i" -eq 0 ] && out="${lines[$i]}" || out="${out}
${lines[$i]}"
done
printf "%s" "$out"
