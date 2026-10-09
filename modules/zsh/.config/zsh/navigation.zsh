opg() {
  local base="$HOME/Projects"
  local dir
  dir=$(find "$base" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -exec test -d {} \; -print | fzf)
  if [[ -n "$dir" ]]; then
    cd "$dir"
  else
    cd "$base"
  fi
}
op() {
  local user_dir="$HOME"
  local dir
  dir=$(find "$user_dir" -mindepth 1 -maxdepth 1 -type d  ! -name '.*' | fzf) && cd "$dir"
}
qss() {
  local dotfiles_dir="$HOME/dotfiles"

  if ! tmux has-session -t setting 2>/dev/null; then
    tmux new-session -d -s setting -c "$dotfiles_dir"
  fi

  local dir
  local base="$HOME/Projects"

  dir=$(find "$base" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | fzf)

  [[ -n "$dir" ]] || return
  local name="$(basename "$dir")"

  if ! tmux has-session -t "$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$dir"
  fi
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
}
