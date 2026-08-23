# Attach to tmux for interactive terminals. Must stay above the p10k instant
# prompt block, since the exec takes over the console. NO_TMUX=1 opts out.
if [[ -o interactive && -t 1 && -z $TMUX && -z $NVIM && -z $NO_TMUX ]] \
  && [[ $TERM_PROGRAM != vscode && $TERM != dumb ]] \
  && command -v tmux &>/dev/null; then
  # Namespace sessions per terminal app, so ghostty windows only ever reclaim
  # ghostty sessions and wezterm only wezterm. tmux forbids '.' and ':' in
  # names, so reduce whatever TERM_PROGRAM holds to bare alphanumerics:
  # ghostty -> ghostty, WezTerm -> wezterm, iTerm.app -> itermapp.
  term_tag=${${TERM_PROGRAM:-term}:l}
  term_tag=${term_tag//[^a-z0-9]/}

  # most recently used session of THIS terminal that no client is on, so a new
  # window continues where you left off without mirroring a live one
  free_session=$(tmux list-sessions \
      -F '#{session_last_attached} #{session_attached} #{session_name}' 2>/dev/null \
    | sort -rn \
    | awk -v tag="$term_tag" '$2 == 0 && $3 ~ "^" tag "-[0-9]+$" { print $3; exit }')

  if [[ -n $free_session ]]; then
    exec tmux attach-session -t "=$free_session"
  else
    # lowest unused suffix, e.g. ghostty-1, ghostty-2
    term_n=1
    while tmux has-session -t "=$term_tag-$term_n" 2>/dev/null; do
      term_n=$((term_n + 1))
    done
    exec tmux new-session -s "$term_tag-$term_n"
  fi
fi

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


# my alias for an easier life
alias v=nvim
alias vim=nvim
alias nv=nvim
alias ovim=vim
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
  local base="$HOME/Documents/git"
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
  local git_base="$HOME/Documents/git"

  if ! tmux has-session -t setting 2>/dev/null; then
    tmux new-session -d -s setting -c "$dotfiles_dir"
  fi

  local dir
  local base="$HOME/Documents/git"

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
bindkey -v
bindkey ^F autosuggest-accept

export MANPAGER="nvim +Man!"

# go.nvim reports GOBIN as unset otherwise; matches the default GOPATH/bin
export GOBIN="$HOME/go/bin"
# homebrew openjdk is keg-only, so java/javac need this to be found
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
