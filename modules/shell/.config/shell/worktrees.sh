# Oh My Zsh's git plugin defines these as aliases.
unalias ga gd 2>/dev/null

# Create a worktree and branch, carrying over uncommitted changes.
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

# Remove the current worktree and its branch.
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
