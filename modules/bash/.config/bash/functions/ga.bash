ga() {
  if [[ -z "$1" ]]; then
    echo "Usage: ga [branch name]"
    return 1
  fi

  local branch="$1"
  local base="$(basename "$PWD")"
  local wt_path="../${base}--${branch}"
  local stash_oid apply_status

  git worktree add -b "$branch" "$wt_path" || return

  if [[ -n "$(git status --porcelain)" ]]; then
    git stash push --include-untracked -m "ga: copy changes to ${branch}" || return
    stash_oid="$(git rev-parse --verify refs/stash)" || return

    git -C "$wt_path" stash apply --index "$stash_oid"
    apply_status=$?
    if ((apply_status != 0)); then
      git stash pop --index
      return "$apply_status"
    fi

    git stash pop --index || return
  fi

  mise trust "$wt_path"
  cd "$wt_path"
}
