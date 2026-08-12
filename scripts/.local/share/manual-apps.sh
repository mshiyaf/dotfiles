#!/usr/bin/env bash
#
# manual-apps.sh - shared per-app version/download-info for apps installed outside
# pacman (or, for command-code, a pacman package AUR can never legitimately own -
# see the note in its section below). Sourced by check-app-updates and update-apps,
# never executed directly.
#
# Each app exposes:
#   <app>_local()          installed version, or empty/non-zero if not installed
#   <app>_remote()          latest upstream version
#   <app>_remote_info()     "<version>\t<download-url>" (install needs the URL too)

# --- cursor ------------------------------------------------------------------

cursor_local() {
  local appimage="/opt/cursor/Cursor.AppImage"
  [ -f "$appimage" ] || return 1
  local tmp
  tmp=$(mktemp -d)
  (cd "$tmp" && "$appimage" --appimage-extract "usr/share/cursor/resources/app/product.json" >/dev/null 2>&1)
  local ver
  ver=$(python3 -c "import json; print(json.load(open('$tmp/squashfs-root/usr/share/cursor/resources/app/product.json'))['version'])" 2>/dev/null) || ver=""
  rm -rf "$tmp"
  [ -n "$ver" ] && echo "$ver"
}

cursor_remote_info() {
  curl -fsSL "https://cursor.com/api/download?platform=linux-x64&releaseTrack=stable" 2>/dev/null |
    python3 -c "
import json, sys, re
d = json.load(sys.stdin)
url = d['downloadUrl']
ver = re.search(r'Cursor-([0-9.]+)-', url).group(1)
print(f'{ver}\t{url}')
" 2>/dev/null
}

cursor_remote() { cursor_remote_info | cut -f1; }

# --- t3code --------------------------------------------------------------------

t3code_local() {
  local desktop="$HOME/.local/share/applications/t3code.desktop"
  [ -f "$desktop" ] || return 1
  grep -oP '(?<=X-AppImage-Version=)\S+' "$desktop"
}

t3code_remote_info() {
  curl -fsSL "https://api.github.com/repos/pingdotgg/t3code/releases/latest" 2>/dev/null |
    python3 -c "
import json, sys
d = json.load(sys.stdin)
ver = d['tag_name'].lstrip('v')
url = next(a['browser_download_url'] for a in d['assets'] if a['name'].endswith('-x86_64.AppImage'))
print(f'{ver}\t{url}')
" 2>/dev/null
}

t3code_remote() { t3code_remote_info | cut -f1; }

# --- chatgpt (codex) -------------------------------------------------------------

CHATGPT_DEB_URL="https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb"
CHATGPT_VERSION_MARKER="$HOME/.local/share/chatgpt-installed-version"

chatgpt_local() {
  # /usr/lib/chatgpt/version is an internal build number, not the package version -
  # we track the real (comparable-to-upstream) version in a marker file instead,
  # written at install time.
  cat "$CHATGPT_VERSION_MARKER" 2>/dev/null
}

chatgpt_remote() {
  curl -fsSL "https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages" 2>/dev/null |
    awk '/^Package: chatgpt$/{f=1} f && /^Version:/{print $2; exit}'
}

chatgpt_remote_info() {
  local ver
  ver=$(chatgpt_remote)
  [ -n "$ver" ] && printf '%s\t%s\n' "$ver" "$CHATGPT_DEB_URL"
}

# --- command-code (desktop GUI app) ---------------------------------------------
#
# NOTE: installed as a pacman package literally named `command-code` (from a manual
# `debtap` build of the .deb from commandcode.ai/desktop), but AUR's `command-code`
# is an unrelated npm CLI tool from a different author with no /opt involvement at
# all. Pacman matches by name only - `paru -S command-code` would delete this app's
# files and replace them with the unrelated CLI tool. Never update this one via
# paru/pacman; update_command_code() below re-extracts the real .deb by hand instead.

command_code_local() {
  local pkgjson="/opt/Command Code/resources/app/package.json"
  [ -f "$pkgjson" ] || return 1
  python3 -c "import json; print(json.load(open('$pkgjson'))['version'])" 2>/dev/null
}

command_code_remote_info() {
  curl -fsSL "https://api.github.com/repos/CommandCodeAI/desktop/releases/latest" 2>/dev/null |
    python3 -c "
import json, sys
d = json.load(sys.stdin)
ver = d['tag_name'].lstrip('v')
url = next(a['browser_download_url'] for a in d['assets'] if a['name'].endswith('-amd64.deb'))
print(f'{ver}\t{url}')
" 2>/dev/null
}

command_code_remote() { command_code_remote_info | cut -f1; }

# --- claude-desktop --------------------------------------------------------------
#
# Official Anthropic apt repo (Debian/Ubuntu only - see
# https://code.claude.com/docs/en/desktop-linux); no Arch/AUR package exists, so
# same manual-.deb-extraction treatment as chatgpt. Ships a chrome-sandbox SUID
# helper that install_deb() in update-apps must re-root/re-setuid after copying,
# since non-root tar extraction drops both.

CLAUDE_DESKTOP_VERSION_MARKER="$HOME/.local/share/claude-desktop-installed-version"

claude_desktop_local() {
  cat "$CLAUDE_DESKTOP_VERSION_MARKER" 2>/dev/null
}

claude_desktop_remote_info() {
  curl -fsSL "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages" 2>/dev/null |
    python3 -c "
import sys, re
text = sys.stdin.read()
paths = re.findall(r'^Filename: (pool/main/c/claude-desktop/claude-desktop_\S+_amd64\.deb)$', text, re.M)
if not paths:
    sys.exit(1)
path = sorted(paths, key=lambda p: [int(x) if x.isdigit() else x for x in re.split(r'(\d+)', p)])[-1]
ver = re.search(r'claude-desktop_([^_]+)_amd64\.deb', path).group(1)
print(f'{ver}\thttps://downloads.claude.ai/claude-desktop/apt/stable/{path}')
" 2>/dev/null
}

claude_desktop_remote() { claude_desktop_remote_info | cut -f1; }
