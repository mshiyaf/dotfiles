# only for X11
if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  export GTK_IM_MODULE=ibus
else
  unset GTK_IM_MODULE
fi
export ZDOTDIR="$HOME/.config/zsh"

# ---------------------------------------------------------------
# Attempt to load encrypted SOPS secrets (once per login)
# ---------------------------------------------------------------
# if [[ -f "$HOME/.config/zsh/secrets.gpg.env" ]]; then
#   # Try to load secrets, but don't block if it fails
#   if command -v sops >/dev/null 2>&1; then
#     load_secrets 2>/dev/null || echo "⚠️  Secrets not loaded. Run 'load-secrets' when ready."
#   fi
# fi

# # ---------------------------------------------------------------
# # Load encrypted SOPS secrets (once per login)
# # ---------------------------------------------------------------
# if [[ -f "$HOME/.config/zsh/secrets.gpg.env" ]]; then
#   # Ensure GPG agent is running and keys are available
#   if command -v gpg-agent >/dev/null 2>&1; then
#     gpg-agent --daemon --quiet 2>/dev/null || true
#   fi
#
#   # Check if we can decrypt before attempting
#   if sops -d "$HOME/.config/zsh/secrets.gpg.env" >/dev/null 2>&1; then
#     set -a
#     source <(sops -d "$HOME/.config/zsh/secrets.gpg.env" |
#              grep -E '^[A-Za-z_][A-Za-z0-9_]*=')
#     set +a
#   else
#     echo "⚠️  Could not decrypt secrets file. Run 'source ~/.zprofile' after GPG is ready."
#   fi
# fi

#if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
#       Hyprland 
#fi
