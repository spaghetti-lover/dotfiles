gpup() {
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD) || return
  git push --set-upstream origin "$branch"
}
