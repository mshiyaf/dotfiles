export ZDOTDIR="$HOME/.config/zsh"
export XDG_CONFIG_HOME="$HOME/.config"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
