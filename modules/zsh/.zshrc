[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git zsh-autosuggestions)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
for highlighting in \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r "$highlighting" ]]; then
    source "$highlighting"
    break
  fi
done
unset highlighting

if command -v fzf >/dev/null; then
  source <(fzf --zsh)
fi
alias f=fzf
alias fp='fzf --preview="bat --color=always {}"'
alias fv='nvim $(fzf -m --preview="bat --color=always {}")'

if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# Initialize try on first use to keep shell startup fast.
if command -v try >/dev/null; then
  try() {
    unfunction try
    eval "$(SHELL=/bin/zsh command try init ~/Projects/tries)"
    try "$@"
  }
fi

alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

alias n=nvim
alias os='nvim ~/.zshrc'
alias ss='source ~/.zshrc'
alias k='kubectl'
alias gr=./gradlew
alias lzg='lazygit'
alias stm='tmux source-file ~/.tmux.conf \;'
alias rm="rm -i"

export PATH="$HOME/.local/nvim/bin:$HOME/.cargo/bin:$PATH"
[[ -d /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin ]] &&
  export PATH="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin:$PATH"
if command -v npm >/dev/null; then
  export NODE_PATH="${NODE_PATH:+$NODE_PATH:}$(npm root -g)"
fi

alias vcf="cd ~/.config/nvim && nvim"
alias python=python3
alias dc=docker-compose
alias lzd=lazydocker
alias gcof='git fetch && git checkout $(git branch | fzf | sed "s/^..//")'

alias c='opencode'
alias cx='printf "\033[2J\033[3J\033[H" && claude --dangerously-skip-permissions'
alias cy='codex -s danger-full-access -a never'
alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'
alias t='tmux attach || tmux new -s main'

bindkey -v
if zle -l | command grep -qx autosuggest-accept; then
  bindkey ^F autosuggest-accept
fi

export EDITOR=nvim
export MANPAGER="nvim +Man!"

export GOBIN="$HOME/go/bin"
[[ -d /opt/homebrew/opt/openjdk/bin ]] && export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
fi

for config in "$HOME/.config/zsh/"*.zsh(N); do
  source "$config"
done
unset config
