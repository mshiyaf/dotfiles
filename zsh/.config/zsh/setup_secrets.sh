#!/usr/bin/env bash
#=====================================================================
#  Arch‑Linux version of the original “install‑gpg‑sops.sh” script
#
#  What it does:
#    • Prompt the user before every action
#    • Install gnupg (if not present)
#    • Install Mozilla SOPS (pacman or AUR)
#    • Optionally remove unwanted PGP keys
#    • Optionally generate a new GPG key
#    • Create a sample ~/secrets.env file
#    • Encrypt that file with the selected GPG key via SOPS
#
#  Requirements:
#    • Bash (tested with 5.x)
#    • sudo privileges (or run the whole script as root)
#=====================================================================

set -euo pipefail # safety: abort on errors, unset vars, pipe failures

# -----------------------------------------------------------------
# Helper: ask for confirmation (default = No)
# -----------------------------------------------------------------
confirm() {
  local prompt="${1:-Are you sure? [y/N]}"
  read -r -p "$prompt " response
  case "$response" in
  [yY][eE][sS] | [yY]) return 0 ;;
  *) return 1 ;;
  esac
}

# -----------------------------------------------------------------
# Helper: install a package via pacman (or yay/paru if requested)
# -----------------------------------------------------------------
install_pkg() {
  local pkg=$1
  # If the package is already installed, skip
  if pacman -Qi "$pkg" &>/dev/null; then
    echo "✔ $pkg is already installed."
    return 0
  fi

  echo "Installing $pkg..."
  sudo pacman -Sy --noconfirm "$pkg"
}

# -----------------------------------------------------------------
# Helper: install SOPS – try pacman first, then optionally AUR
# -----------------------------------------------------------------
install_sops() {
  if pacman -Qi sops &>/dev/null; then
    echo "✔ sops is already installed."
    return 0
  fi

  # Try the official repository first
  if pacman -Ss '^sops$' | grep -q '^community/sops'; then
    install_pkg sops
    return 0
  fi

  # If we get here, sops isn’t in the repos (maybe a very old mirror)
  # Offer to pull it from the AUR using yay or paru, if either is present.
  if command -v yay &>/dev/null || command -v paru &>/dev/null; then
    local aur_helper
    aur_helper=$(command -v yay || command -v paru)

    if confirm "sops not found in repos. Install it from the AUR with $aur_helper? [y/N]"; then
      echo "Installing sops from AUR via $aur_helper..."
      $aur_helper -S --noconfirm sops
      return 0
    else
      echo "Skipping sops installation."
      return 1
    fi
  else
    echo "sops package not available in repos and no AUR helper (yay/paru) detected."
    echo "You can manually install it later (e.g. $(yay -S sops))."
    return 1
  fi
}

# -----------------------------------------------------------------
# MAIN ----------------------------------------------------------------
# -----------------------------------------------------------------

# 1. Install GPG (gnupg)
if confirm "Do you want to install GPG (GNU Privacy Guard)? [y/N]"; then
  install_pkg gnupg
else
  echo "⏭ Skipping GPG installation."
fi

# 2. Install SOPS
if confirm "Do you want to install Mozilla SOPS? [y/N]"; then
  install_sops || { echo "⚠️  SOPS installation failed – script will continue but encryption won't work."; }
else
  echo "⏭ Skipping SOPS installation."
fi

# 3. Optionally delete unwanted PGP keys
if confirm "Do you want to remove any default SOPS PGP keys? [y/N]"; then
  echo "Listing current GPG public keys:"
  gpg --list-keys
  echo "Enter the fingerprint of the key you want to delete (or press Enter to skip):"
  read -r del_fpr
  if [[ -n "$del_fpr" ]]; then
    echo "Deleting key $del_fpr ..."
    gpg --delete-keys "$del_fpr"
    gpg --delete-secret-keys "$del_fpr"
  else
    echo "No key selected – nothing deleted."
  fi
else
  echo "⏭ Skipping key removal."
fi

# 4. Optionally generate a new GPG key
if confirm "Do you want to generate a new GPG key for encrypting secrets? [y/N]"; then
  echo "Launching the GPG key generation wizard..."
  gpg --full-generate-key
else
  echo "⏭ Skipping GPG key generation."
fi

# 5. Create a sample secrets.env file
if confirm "Do you want to create a new secrets.env file at ~/secrets.env? [y/N]"; then
  cat <<'EOL' >"$HOME/secrets.env"
# ------------------------------------------------------------------
#  Sample secrets file – edit the values to match your environment.
#  Keep this file *outside* of version control!
# ------------------------------------------------------------------
API_KEY=your_api_key_here
SECRET_KEY=your_secret_key_here
EOL
  echo "✅ Created ~/secrets.env. Edit it with your real secrets."
else
  echo "⏭ Skipping secrets.env creation."
fi

# -----------------------------------------------------------------
# Encryption phase – only proceed if we have both the file and SOPS
# -----------------------------------------------------------------
if [[ ! -f "$HOME/secrets.env" ]]; then
  echo "⚠️  ~/secrets.env not found – aborting encryption step."
  exit 1
fi

if ! command -v sops &>/dev/null; then
  echo "⚠️  sops binary not found – cannot encrypt. Install SOPS and re‑run."
  exit 1
fi

echo "===== Available GPG keys (public) ====="
gpg --list-keys --fingerprint

echo "Enter the fingerprint of the GPG key you want to use for encryption:"
read -r enc_fpr

if [[ -z "$enc_fpr" ]]; then
  echo "❌ No fingerprint supplied – aborting."
  exit 1
fi

# Encrypt the file
echo "Encrypting ~/secrets.env → ~/secrets.gpg.env ..."
sops --encrypt --pgp "$enc_fpr" "$HOME/secrets.env" >"$HOME/code/dotfiles/zsh/.config/zsh/secrets.gpg.env"

echo "✅ Encryption complete! Encrypted file saved as ~/secrets.gpg.env"
echo "You can now safely store this file in a repository (it will be PGP‑encrypted)."

echo "✨ Setup finished! ✨"
