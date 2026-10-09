_herdr_ratio() { printf "%.4f" $(( 1.0 * $1 / $2 )); }

_herdr_split() {
  herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus |
    jq -r '.result.pane.pane_id'
}

hdl() {
  [[ -z $1 ]] && { echo "Usage: hdl <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdl."; return 1; }

  local current_dir="$PWD"
  local ai="$1" ai2="$2"
  local editor_pane ai_pane ai2_pane

  editor_pane="$HERDR_PANE_ID"

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

  _herdr_split "$editor_pane" down 0.85 "$current_dir" >/dev/null
  ai_pane=$(_herdr_split "$editor_pane" right 0.7 "$current_dir")

  if [[ -n $ai2 ]]; then
    ai2_pane=$(_herdr_split "$ai_pane" down 0.5 "$current_dir")
    herdr pane run "$ai2_pane" "$ai2" >/dev/null
  fi

  herdr pane run "$ai_pane" "$ai" >/dev/null
  herdr pane run "$editor_pane" "$EDITOR ." >/dev/null
}

hdh() {
  [[ -z $1 ]] && { echo "Usage: hdh <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdh."; return 1; }

  local current_dir="$PWD"
  local ai="$1" ai2="$2"
  local diff_pane ai_pane ai2_pane

  diff_pane="$HERDR_PANE_ID"

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

  _herdr_split "$diff_pane" down 0.85 "$current_dir" >/dev/null
  ai_pane=$(_herdr_split "$diff_pane" right 0.7 "$current_dir")

  if [[ -n $ai2 ]]; then
    ai2_pane=$(_herdr_split "$ai_pane" down 0.5 "$current_dir")
    herdr pane run "$ai2_pane" "$ai2" >/dev/null
  fi

  herdr pane run "$ai_pane" "$ai" >/dev/null
  herdr pane run "$diff_pane" "hunk diff --watch" >/dev/null
  herdr pane focus --pane "$diff_pane" --direction right >/dev/null
}

hds() {
  [[ -n $1 ]] && { echo "Usage: hds"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hds."; return 1; }

  local current_dir="$PWD"
  local editor_pane diff_pane terminal_pane opencode_pane

  editor_pane="$HERDR_PANE_ID"

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

  terminal_pane=$(_herdr_split "$editor_pane" down 0.5 "$current_dir")
  diff_pane=$(_herdr_split "$editor_pane" right 0.5 "$current_dir")
  opencode_pane=$(_herdr_split "$terminal_pane" right 0.5 "$current_dir")

  herdr pane run "$editor_pane" "$EDITOR ." >/dev/null
  herdr pane run "$diff_pane" "hunk diff --watch" >/dev/null
  herdr pane run "$opencode_pane" "opencode" >/dev/null
}

hdlm() {
  [[ -z $1 ]] && { echo "Usage: hdlm <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hdlm."; return 1; }

  setopt local_options null_glob

  local ai="$1" ai2="$2"
  local base_dir="$PWD"
  local first=true
  local dir dirpath pane_id cmd

  herdr workspace rename "$HERDR_WORKSPACE_ID" "$(basename "$base_dir")" >/dev/null

  for dir in "$base_dir"/*/; do
    dirpath="${dir%/}"
    cmd="hdl ${(q)ai}"
    [[ -n $ai2 ]] && cmd+=" ${(q)ai2}"

    if $first; then
      herdr pane run "$HERDR_PANE_ID" "cd ${(q)dirpath} && $cmd" >/dev/null
      first=false
    else
      pane_id=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$dirpath" --no-focus |
        jq -r '.result.root_pane.pane_id')
      herdr pane run "$pane_id" "$cmd" >/dev/null
    fi
  done
}

hsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: hsl <pane_count> <command>"; return 1; }
  [[ -z $HERDR_PANE_ID ]] && { echo "You must start herdr to use hsl."; return 1; }

  local count="$1" cmd="$2"
  local current_dir="$PWD"
  local -a columns panes
  local cols=1 k index rows j last pane

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$current_dir")" >/dev/null

  while (( cols * cols < count )); do ((cols++)); done

  columns=("$HERDR_PANE_ID")
  for (( k = 1; k < cols; k++ )); do
    columns+=("$(_herdr_split "${columns[-1]}" right "$(_herdr_ratio 1 $((cols - k + 1)))" "$current_dir")")
  done

  for (( index = 1; index <= cols; index++ )); do
    rows=$(( count / cols ))
    (( index <= count % cols )) && (( rows++ ))
    last="${columns[index]}"
    panes+=("$last")
    for (( j = 1; j < rows; j++ )); do
      last=$(_herdr_split "$last" down "$(_herdr_ratio 1 $((rows - j + 1)))" "$current_dir")
      panes+=("$last")
    done
  done

  for pane in "${panes[@]}"; do
    herdr pane run "$pane" "$cmd" >/dev/null
  done
}
