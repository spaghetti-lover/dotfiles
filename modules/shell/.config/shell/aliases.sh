# Omarchy's bash already defines ls/lt, n, c/cx/cy and t, so those live in .zshrc.
alias f=fzf
alias fp='fzf --preview="bat --color=always {}"'
alias fv='nvim $(fzf -m --preview="bat --color=always {}")'

alias k='kubectl'
alias gr=./gradlew
alias lzg='lazygit'
alias lzd=lazydocker
alias dc=docker-compose
alias python=python3
alias rm="rm -i"
alias stm='tmux source-file ~/.tmux.conf \;'
alias vcf="cd ~/.config/nvim && nvim"
alias gcof='git fetch && git checkout $(git branch | fzf | sed "s/^..//")'

alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'
