# for profiling, also check the last 
# Show profiling results
# zprof
# zmodload zsh/zprof

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(
    git
    vi-mode
)

source $ZSH/oh-my-zsh.sh

source ~/.config/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh
# Fast syntax highlighting (replaces zsh-syntax-highlighting)
# Install: git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ~/code/dotfiles/zsh/.config/zsh/plugins/fast-syntax-highlighting
source ~/.config/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
# Fast autosuggestions (replaces zsh-autosuggestions)
# Install: git clone https://github.com/zsh-users/zsh-autosuggestions ~/code/dotfiles/zsh/.config/zsh/plugins/zsh-autosuggestions
source ~/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh


export KEYTIMEOUT=1

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Edit line in vim with ctrl-v:
autoload edit-command-line; zle -N edit-command-line
bindkey '^v' edit-command-line

# # Load aliases and shortcuts if existent.
# export NVM_DIR="$HOME/.config/nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f "$HOME/.config/zsh/.shortcutrc" ] && source "$HOME/.config/zsh/.shortcutrc"
[ -f "$HOME/.config/zsh/.aliasrc" ] && source "$HOME/.config/zsh/.aliasrc"
[ -f "$HOME/.config/zsh/.exports" ] && source "$HOME/.config/zsh/.exports"

# fnm
if [[ -f "$HOME/.local/share/fnm/fnm" ]]; then
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
fi

# zoxide  
if [[ -f "$HOME/.local/bin/zoxide" ]]; then
    eval "$(zoxide init zsh)"
fi

# bun completions
[ -s "/home/mshiyaf/.bun/_bun" ] && source "/home/mshiyaf/.bun/_bun"
[ -f "/home/mshiyaf/.ghcup/env" ] && . "/home/mshiyaf/.ghcup/env" # ghcup-env

# Load profile last
[[ -r "$HOME/.zprofile" ]] && source "$HOME/.zprofile"

# Show profiling results
# zprof
