# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Add wisely, as too many plugins slow down shell startup.
plugins=(git)
plugins=(git zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf
source <(fzf --zsh)
alias f=fzf
# preview with bat
alias fp='fzf --preview="bat --color=always {}"'
# open neovim with select file by tab
alias fv='nvim $(fzf -m --preview="bat --color=always {}")'

# zoxide: `z <part-of-path>` jumps to a directory you have visited, `zi` picks one with fzf
eval "$(zoxide init zsh)"

# try: date-stamped scratch directories for experiments under ~/Projects/tries.
# `try init` shells out to ruby, so defer it to the first call instead of paying for it
# on every prompt. The stub unfunctions itself, then the real init defines the real `try`.
if command -v try >/dev/null; then
  try() {
    unfunction try
    eval "$(SHELL=/bin/zsh command try init ~/Projects/tries)"
    try "$@"
  }
fi

# eza: ls replacement with icons, colors and git status. `man eza` for the manual.
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

# my alias for an easier life
# the only nvim alias; `vim` is left alone so it still reaches /usr/bin/vim
alias n=nvim
alias os='nvim ~/.zshrc'
alias ss='source ~/.zshrc'
alias k='kubectl'
alias gr=./gradlew
alias lzg='lazygit'
# source tmux
alias stm='tmux source-file ~/.tmux.conf \;'
# confirm before remove something... fk.
alias rm="rm -i"

# PATH
export PATH="$HOME/.local/nvim/bin:$HOME/.cargo/bin:$PATH"
export PATH="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin:$PATH"
export NODE_PATH=$NODE_PATH:$(npm root -g)

alias vcf="cd ~/.config/nvim && nvim"
alias python=python3
alias dc=docker-compose
alias lzd=lazydocker
# fetch then allow to fuzzy finding branches
alias gcof='git fetch && git checkout $(git branch | fzf | sed "s/^..//")'
# push with set upstream for the current branch
gpup() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  git push --set-upstream origin "$branch"
}
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
# quick session
qss() {
  local dotfiles_dir="$HOME/dotfiles"
  local git_base="$HOME/Projects"

  if ! tmux has-session -t setting 2>/dev/null; then
    tmux new-session -d -s setting -c "$dotfiles_dir"
  fi

  local dir
  local base="$HOME/Projects"

  dir=$(find "$base" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | fzf)

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

# ---------------------------------------------------------------------
# Omarchy tmux layouts (https://omarchy.org/manual/navigation)
# Ported from bash: zsh arrays are 1-indexed, so panes[1] is the first
# pane where upstream writes panes[0] (which is empty in zsh).
# ---------------------------------------------------------------------

# Dev layout: editor left, AI right, terminal below.
# Usage: tdl <c|cx|cy|other_ai> [<second_ai>]
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdl."; return 1; }

  local current_dir="$PWD"
  local ai="$1" ai2="$2"
  local editor_pane ai_pane ai2_pane

  # TMUX_PANE is stable even if the active window changes under us
  editor_pane="$TMUX_PANE"

  tmux rename-window -t "$editor_pane" "$(basename "$current_dir")"

  # terminal along the bottom, 15%
  tmux split-window -v -p 15 -t "$editor_pane" -c "$current_dir"

  # AI on the right, 30%
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$editor_pane" "$EDITOR ." C-m
  tmux select-pane -t "$editor_pane"
}

# The same layout with a diff watcher in place of the editor: hunk left, AI right, terminal below.
# Usage: tdh <c|cx|cy|other_ai> [<second_ai>]
tdh() {
  [[ -z $1 ]] && { echo "Usage: tdh <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdh."; return 1; }

  local current_dir="$PWD"
  local ai="$1" ai2="$2"
  local diff_pane ai_pane ai2_pane

  diff_pane="$TMUX_PANE"

  tmux rename-window -t "$diff_pane" "$(basename "$current_dir")"

  # terminal along the bottom, 15%
  tmux split-window -v -p 15 -t "$diff_pane" -c "$current_dir"

  # AI on the right, 30%
  ai_pane=$(tmux split-window -h -p 30 -t "$diff_pane" -c "$current_dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$ai2" C-m
  fi

  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux send-keys -t "$diff_pane" "hunk diff --watch" C-m
  # the diff pane is only there to be read, so land in the agent
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

# One tdl window per subdirectory of the current directory.
# Usage: tdlm <c|cx|cy|other_ai> [<second_ai>]
tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <c|cx|cy|other_ai> [<second_ai>]"; return 1; }
  [[ -z $TMUX ]] && { echo "You must start tmux to use tdlm."; return 1; }

  # zsh errors on a glob that matches nothing; upstream bash just skips
  setopt local_options null_glob

  local ai="$1" ai2="$2"
  local base_dir="$PWD"
  local first=true
  local dir dirpath pane_id

  # tmux disallows dots and colons in session names
  tmux rename-session "$(basename "$base_dir" | tr '.:' '--')"

  for dir in "$base_dir"/*/; do
    [[ -d $dir ]] || continue
    dirpath="${dir%/}"

    if $first; then
      # reuse the current window for the first project
      tmux send-keys -t "$TMUX_PANE" "cd '$dirpath' && tdl $ai $ai2" C-m
      first=false
    else
      pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}')
      tmux send-keys -t "$pane_id" "tdl $ai $ai2" C-m
    fi
  done
}

# Swarm layout: N tiled panes all running the same command.
# Usage: tsl <pane_count> <command>
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
  # herdr has no focus-by-id, so step right out of the diff pane instead
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

# AI agents, and the tdl shorthands built on them
alias c='opencode'
alias cx='printf "\033[2J\033[3J\033[H" && claude --dangerously-skip-permissions'
alias cy='codex -s danger-full-access -a never'
alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'
# 'main' matches the session cmd-alt-enter creates
alias t='tmux attach || tmux new -s main'

bindkey -v
bindkey ^F autosuggest-accept

export EDITOR=nvim   # tdl opens `$EDITOR .` in its left pane
export MANPAGER="nvim +Man!"

# where `go install` drops binaries; matches the default GOPATH/bin
export GOBIN="$HOME/go/bin"
# homebrew openjdk is keg-only, so java/javac need this to be found
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# mise: per-project runtime versions (node, python, go, java, ...); must come after the
# PATH exports above so its shims win
eval "$(mise activate zsh)"
