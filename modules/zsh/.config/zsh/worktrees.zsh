unalias ga gd 2>/dev/null

ga() {
  [[ -z $1 ]] && { echo "Usage: ga <branch>"; return 1; }

  local wt_path="../$(basename "$PWD")--$1"

  git worktree add -b "$1" "$wt_path" || return 1
  mise trust "$wt_path"
  cd "$wt_path"
}

gd() {
  gum confirm "Remove worktree and branch?" || return

  local cwd="$PWD" worktree root branch

  worktree="$(basename "$cwd")"
  root="${worktree%%--*}"
  branch="${worktree#*--}"

  [[ "$root" == "$worktree" ]] && return

  cd "../$root"
  git worktree remove "$cwd" --force || return 1
  git branch -D "$branch"
}
