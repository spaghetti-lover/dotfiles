export EDITOR=nvim
export MANPAGER="nvim +Man!"
export GOBIN="$HOME/go/bin"

export PATH="$HOME/.local/nvim/bin:$HOME/.cargo/bin:$PATH"
[[ -d /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin ]] &&
  export PATH="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin:$PATH"
[[ -d /opt/homebrew/opt/openjdk/bin ]] && export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
