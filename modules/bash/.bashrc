# Omarchy environment must also load in non-interactive shells.
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

[[ $- != *i* ]] && return

source "$OMARCHY_PATH/default/bash/rc"

[[ -r "$HOME/.config/bash/functions/ga.bash" ]] && source "$HOME/.config/bash/functions/ga.bash"

alias lzg='lazygit'

[[ -r "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
[[ -r "$HOME/.pandora_env/activate" ]] && source "$HOME/.pandora_env/activate"
