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

# GitHub's API allows only 60 unauthenticated requests an hour, which a couple of
# checks plus an update run can exhaust. Reuse the gh CLI's login when there is
# one (5,000/hour); uv's own self-update check reads UV_GITHUB_TOKEN.
GITHUB_TOKEN=${GITHUB_TOKEN:-$(gh auth token 2>/dev/null || true)}
[ -n "$GITHUB_TOKEN" ] && export UV_GITHUB_TOKEN=${UV_GITHUB_TOKEN:-$GITHUB_TOKEN}

github_api() {
  if [ -n "$GITHUB_TOKEN" ]; then
    curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/$1"
  else
    curl -fsSL "https://api.github.com/$1"
  fi
}

# --- t3code --------------------------------------------------------------------

t3code_local() {
  local desktop="$HOME/.local/share/applications/t3code.desktop"
  [ -f "$desktop" ] || return 1
  grep -oP '(?<=X-AppImage-Version=)\S+' "$desktop"
}

t3code_remote_info() {
  github_api "repos/pingdotgg/t3code/releases/latest" 2>/dev/null |
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
  github_api "repos/CommandCodeAI/desktop/releases/latest" 2>/dev/null |
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

# --- craft apps (storytold's Craft App Suite) ----------------------------------
#
# Every Craft app publishes the same release layout on GitHub
# (storytold/<app>: <app>-<ver>-linux-x86_64.AppImage + SHA256SUMS.txt), so one
# generic handler covers all of them - adding an app is one line in CRAFT_LABEL.
# Installed per-user in ~/Applications (no sudo), which is also where the
# upstream ArtCraft Launcher looks for AppImages. The AppImage ships its own
# ai.storyteller.<app>.desktop (with X-AppImage-Version) and icon; update-apps
# installs both, so the installed version is read back from that .desktop.
# These functions take the app id as $1.

declare -A CRAFT_LABEL=(
  [photocraft]="PhotoCraft"
  [pdfcraft]="PdfCraft"
  [wordcraft]="WordCraft"
  [deckcraft]="DeckCraft"
  [gridcraft]="GridCraft"
)
CRAFT_APPS=(photocraft pdfcraft wordcraft deckcraft gridcraft)
CRAFT_DIR="$HOME/Applications"

is_craft_app() { [ -n "${CRAFT_LABEL[$1]+x}" ]; }

craft_local() {
  local desktop="$HOME/.local/share/applications/ai.storyteller.$1.desktop"
  [ -f "$desktop" ] || return 1
  grep -oP '(?<=X-AppImage-Version=)\S+' "$desktop"
}

# Prints "<version>\t<appimage-url>\t<sha256sums-url>".
craft_remote_info() {
  github_api "repos/storytold/$1/releases/latest" 2>/dev/null |
    python3 -c "
import json, sys
d = json.load(sys.stdin)
ver = d['tag_name'].lstrip('v')
assets = {a['name']: a['browser_download_url'] for a in d['assets']}
url = next(u for n, u in assets.items() if n.endswith('-linux-x86_64.AppImage'))
print(f\"{ver}\t{url}\t{assets['SHA256SUMS.txt']}\")
" 2>/dev/null
}

craft_remote() { craft_remote_info "$1" | cut -f1; }

# --- self-updating tools ---------------------------------------------------------
#
# CLIs and toolchains outside pacman that ship their own updater (all under
# $HOME, no sudo). update-apps runs TOOL_UPDATE; both scripts report status via
# tool_status. A tool has either TOOL_LATEST (prints the newest upstream
# version, compared with TOOL_VERSION) or, for toolchains managing several
# components, a TOOL_OUTDATED function (prints one line per outdated component,
# nothing when current, non-zero exit when the check itself failed). agy has
# neither - its updater endpoint isn't public - so its status is "unknown".

declare -A TOOL_LABEL=(
  [claude]="Claude Code"
  [codex]="Codex CLI"
  [amp]="Amp CLI"
  [agy]="Antigravity CLI"
  [herdr]="herdr"
  [opencode]="OpenCode"
  [opencode2]="OpenCode 2 (beta)"
  [mise]="mise runtimes + npm tools"
  [rustup]="Rust (rustup)"
  [uv]="uv + uv tools"
)
declare -A TOOL_UPDATE=(
  [claude]="claude update"
  [codex]="codex update"
  [amp]="amp update"
  [agy]="agy update"
  [herdr]="herdr update"
  [opencode]="opencode upgrade"
  # bun's global dir resolves to ~ (~/package.json), shared with the Playwright
  # the browser skill imports from ~/node_modules - `add -g` updates in place.
  [opencode2]="bun add -g --trust @opencode-ai/cli@latest"
  # Upgrades runtimes within the versions pinned in ~/.config/mise/config.toml,
  # plus npm-backed tools there (firebase-tools). mise itself comes from pacman.
  [mise]="mise upgrade"
  [rustup]="rustup update"
  [uv]="uv self update && uv tool upgrade --all"
)
# Installed version, normalised to match TOOL_LATEST's format.
declare -A TOOL_VERSION=(
  [claude]="claude --version | cut -d' ' -f1"
  [codex]="codex --version | cut -d' ' -f2"
  [amp]="amp --version | cut -d' ' -f1"
  [agy]="agy --version"
  [herdr]="herdr --version | cut -d' ' -f2"
  [opencode]="opencode --version"
  [opencode2]="opencode2 --version | cut -d' ' -f2 | sed 's/^v//'"
  [mise]="mise --version | cut -d' ' -f1"
  [rustup]="rustc --version | cut -d' ' -f2"
  [uv]="uv --version | cut -d' ' -f2"
)
declare -A TOOL_LATEST=(
  [claude]="npm view @anthropic-ai/claude-code version"
  [codex]="npm view @openai/codex version"
  [amp]="npm view @sourcegraph/amp version"
  [opencode]="npm view opencode-ai version"
  [opencode2]="npm view @opencode-ai/cli dist-tags.latest"
  [herdr]="curl -fsSL https://herdr.dev/latest.json | python3 -c 'import json, sys; print(json.load(sys.stdin)[\"version\"])'"
)
declare -A TOOL_OUTDATED=(
  [mise]=tool_outdated_mise
  [rustup]=tool_outdated_rustup
  [uv]=tool_outdated_uv
)
TOOL_ORDER=(claude codex amp agy herdr opencode opencode2 mise rustup uv)

tool_outdated_mise() {
  mise outdated --json 2>/dev/null | python3 -c "
import json, sys
for name, t in json.load(sys.stdin).items():
    print(f\"{name} {t['current']} -> {t['latest']}\")
"
}

tool_outdated_rustup() {
  local out
  out=$(rustup check 2>/dev/null) && [ -n "$out" ] || return 1
  grep 'Update available' <<<"$out" |
    sed -E 's/-x86_64-unknown-linux-gnu//; s/ - Update available : / /; s/ \([^)]*\)//g' || true
}

tool_outdated_uv() {
  local self tools
  self=$(uv self update --dry-run 2>&1) || return 1
  tools=$(uv tool list --outdated 2>/dev/null) || return 1
  grep -q 'Would update' <<<"$self" && echo "uv (self)"
  grep -E '^\S+ v\S+ \[latest: ' <<<"$tools" |
    sed -E 's/^(\S+) v(\S+) \[latest: ([^]]+)\]/\1 \2 -> \3/' || true
}

# The binary each tool's updater needs - the first word of its update command.
tool_bin() { local cmd="${TOOL_UPDATE[$1]}"; echo "${cmd%% *}"; }

tool_installed() { command -v "$(tool_bin "$1")" >/dev/null 2>&1; }

# Prints "<state>\t<installed>\t<detail>"; state is current, outdated or unknown.
tool_status() {
  local key="$1" installed latest detail
  installed=$(bash -c "${TOOL_VERSION[$key]}" 2>/dev/null | head -1)
  if [ -n "${TOOL_LATEST[$key]+x}" ]; then
    latest=$(bash -c "${TOOL_LATEST[$key]}" 2>/dev/null | head -1)
    if [ -z "$latest" ]; then
      printf 'unknown\t%s\tcouldn'\''t reach upstream\n' "$installed"
    elif [ "$latest" = "$installed" ]; then
      printf 'current\t%s\t\n' "$installed"
    else
      printf 'outdated\t%s\t%s\n' "$installed" "$latest"
    fi
  elif [ -n "${TOOL_OUTDATED[$key]+x}" ]; then
    if detail=$("${TOOL_OUTDATED[$key]}"); then
      if [ -z "$detail" ]; then
        printf 'current\t%s\t\n' "$installed"
      else
        printf 'outdated\t%s\t%s\n' "$installed" "$(paste -sd ',' <<<"$detail" | sed 's/,/, /g')"
      fi
    else
      printf 'unknown\t%s\tcheck failed\n' "$installed"
    fi
  else
    printf 'unknown\t%s\tno public version check\n' "$installed"
  fi
}
