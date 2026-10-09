tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

  local current_dir="$PWD"
  local ai="$1" ai2="$2"
  local editor_pane ai_pane ai2_pane

  editor_pane="$TMUX_PANE"

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
  tmux select-pane -t "$editor_pane"
}

tdh() {
  [[ -z $1 ]] && { echo "Usage: tdh <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdh."; return 1; }

  local current_dir="$PWD"
  local ai="$1" ai2="$2"
  local diff_pane ai_pane ai2_pane

  diff_pane="$TMUX_PANE"

  tmux rename-window -t "$diff_pane" "$(basename "$current_dir")"

  tmux split-window -v -p 15 -t "$diff_pane" -c "$current_dir"

  ai_pane=$(tmux split-window -h -p 30 -t "$diff_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$diff_pane" "hunk diff --watch" C-m
  tmux select-pane -t "$ai_pane"
}

tds() {
  [[ -n $1 ]] && { echo "Usage: tds"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tds."; return 1; }

  local current_dir="$PWD"
  local editor_pane diff_pane terminal_pane opencode_pane

  editor_pane="$TMUX_PANE"

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  terminal_pane=$(tmux split-window -v -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  diff_pane=$(tmux split-window -h -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')
  opencode_pane=$(tmux split-window -h -p 50 -t "$terminal_pane" -c "$current_dir" -P -F '#{pane_id}')

  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
  tmux send-keys -t "$diff_pane" "hunk diff --watch" C-m
  tmux send-keys -t "$opencode_pane" "opencode" C-m

  tmux select-pane -t "$editor_pane"
}

tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }

  setopt local_options null_glob

  local ai="$1" ai2="$2"
  local base_dir="$PWD"
  local first=true
  local dir dirpath pane_id

  tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    dirpath="${dir%/}"

    if $first; then
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
      first=false
    else
      pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
    fi
  done
}

tsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tsl."; return 1; }

  local count="$1" cmd="$2"
  local current_dir="$PWD"
  local -a panes
  local new_pane pane

  tmux rename-window -t "$TMUX_PANE" "$(basename "$current_dir")"
  panes+=("$TMUX_PANE")

  while (( ${#panes[@]} < count )); do
    new_pane=$(tmux split-window -h -t "${panes[-1]}" -c "$current_dir" -P -F '#{pane_id}')
    panes+=("$new_pane")
    tmux select-layout -t "${panes[1]}" tiled
  done

  for pane in "${panes[@]}"; do
    tmux send-keys -t "$pane" "$cmd" C-m
  done

  tmux select-pane -t "${panes[1]}"
}
