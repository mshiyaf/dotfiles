export GTK_IM_MODULE=ibus
export ZDOTDIR="$HOME/.config/zsh"

# ---------------------------------------------------------------
# Load encrypted SOPS secrets (once per login)
# ---------------------------------------------------------------
if [[ -f "$HOME/.config/zsh/secrets.gpg.env" ]]; then
  set -a
  source <(sops -d "$HOME/.config/zsh/secrets.gpg.env" |
           grep -E '^[A-Za-z_][A-Za-z0-9_]*=')
  set +a
fi

#if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
#       Hyprland 
#fi
