#!/usr/bin/env bash
#
# bootstrap.sh - guided setup of these dotfiles on an Arch-based machine.
#
# Steps (install mode):
#   1. Check the system is Arch-based and we are not root.
#   2. Detect the window manager / desktop and pick a profile: the editor,
#      shell and CLI packages every machine gets, plus the packages that belong
#      to that desktop (niri, hyprland, omarchy, i3, or none).
#   3. Back up every existing file the chosen packages would replace
#      (copied, then archived as a .tar.gz; nothing is deleted yet).
#   4. Check the apps each package needs (deps.conf) and offer to install the
#      missing ones: official repos with pacman, AUR only after a separate
#      confirmation, vendor installers printed for you to run.
#   5. Stow the packages (via make, so voxtype keeps its folded layout).
#   6. Offer the optional system files (keyd, udev, sysctl) and print what is left.
#
# Usage:
#   ./bootstrap.sh                      Guided setup (asks before every change)
#   ./bootstrap.sh --check              Read-only report: links and missing apps
#   ./bootstrap.sh --dry-run            Show every step without changing anything
#   ./bootstrap.sh --profile hyprland   Skip desktop detection
#   ./bootstrap.sh --add "lazygit btop" Stow extra packages too
#
# Environment: TARGET (default $HOME) is where packages are linked.

set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET=${TARGET:-$HOME}
DEPS_FILE=$REPO/deps.conf
# tmux.conf and a few zsh aliases hardcode this checkout path.
EXPECTED_REPO=$HOME/dev/github.com/mshiyaf/dotfiles

# Desktop-specific packages per profile. Everything else in the Makefile's
# DEFAULT_PACKAGES is desktop-independent and goes on every machine.
PROFILES=(niri hyprland omarchy i3 none)
declare -A PROFILE_PKGS=(
  [niri]="niri noctalia voxtype"
  [hyprland]="hypr waybar swaync rofi wlogout wallust swappy Kvantum qt5ct qt6ct"
  [omarchy]="omarchy"
  [i3]="i3 i3status picom rofi"
  [none]=""
)
# Must match FOLDED_PACKAGES in the Makefile.
FOLDED_PACKAGES=" voxtype "

BACKUP_ROOT=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backup
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=$BACKUP_ROOT/$STAMP

MODE=install DRY_RUN=0 PROFILE="" ADD=""

if [ -t 1 ]; then B=$'\e[1m' R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' C=$'\e[36m' N=$'\e[0m'; else B="" R="" G="" Y="" C="" N=""; fi
step() { printf '\n%s==> %s%s\n' "$B$C" "$*" "$N"; }
ok()   { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; }
bad()  { printf '  %s✗%s %s\n' "$R" "$N" "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { bad "$*" >&2; exit 1; }

# Ask a yes/no question on the terminal; default is no. Dry runs never ask.
confirm() {
  local a
  (( DRY_RUN )) && { info "[dry-run] would ask: $1"; return 1; }
  [ -r /dev/tty ] || return 1
  read -r -p "  $1 [y/N] " a </dev/tty || return 1
  [[ $a =~ ^[Yy] ]]
}
run() {
  if (( DRY_RUN )); then printf '    %s[dry-run]%s' "$Y" "$N"; printf ' %q' "$@"; echo; else "$@"; fi
}
is_folded() { [[ $FOLDED_PACKAGES == *" $1 "* ]]; }

usage() { sed -n '3,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case $1 in
    --check) MODE=check ;;
    --dry-run|-n) DRY_RUN=1 ;;
    --profile) PROFILE=${2:-}; shift ;;
    --profile=*) PROFILE=${1#*=} ;;
    --add) ADD="$ADD ${2:-}"; shift ;;
    --add=*) ADD="$ADD ${1#*=}" ;;
    -h|--help) usage ;;
    *) echo "unknown option: $1" >&2; usage 2 ;;
  esac
  shift
done
ADD=${ADD//,/ }

# --- 1. system ------------------------------------------------------------

check_system() {
  step "Checking the system"
  [ -r /etc/os-release ] || die "no /etc/os-release; only Arch-based systems are supported"
  local id like name
  IFS='|' read -r id like name < <(. /etc/os-release; echo "${ID:-}|${ID_LIKE:-}|${PRETTY_NAME:-${ID:-unknown}}")
  if [[ $id == arch || " $like " == *" arch "* ]] && command -v pacman >/dev/null; then
    ok "$name (Arch-based)"
  else
    die "$name is not Arch-based. deps.conf uses Arch package names, so this script stops here."
  fi
  [ "$(id -u)" -ne 0 ] || die "run this as your normal user; it asks for sudo only when it installs something"
  if [ "$REPO" != "$EXPECTED_REPO" ]; then
    warn "repo is at $REPO, but tmux.conf and some zsh aliases expect $EXPECTED_REPO"
  fi

  local core=() c
  for c in git stow make; do command -v "$c" >/dev/null || core+=("$c"); done
  if (( ${#core[@]} )); then
    [ "$MODE" = check ] && die "missing ${core[*]}; install with: sudo pacman -S --needed ${core[*]}"
    warn "bootstrap needs: ${core[*]}"
    confirm "Install them now with sudo pacman -S --needed ${core[*]}?" || die "cannot continue without ${core[*]}"
    run sudo pacman -S --needed "${core[@]}"
  else
    ok "git, stow and make are installed"
  fi
}

# --- 2. desktop / profile --------------------------------------------------

detect_profile() {
  local cur="${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}:${DESKTOP_SESSION:-}"
  cur=${cur,,}
  if [ -d "$HOME/.local/share/omarchy" ]; then echo omarchy
  elif [[ $cur == *niri* ]]; then echo niri
  elif [[ $cur == *hyprland* ]]; then echo hyprland
  elif [[ $cur == *i3* ]]; then echo i3
  elif [[ -n ${cur//:/} ]]; then echo none     # GNOME, KDE, ... : no WM configs
  elif command -v niri >/dev/null; then echo niri
  elif command -v Hyprland >/dev/null || command -v hyprland >/dev/null; then echo hyprland
  elif command -v i3 >/dev/null; then echo i3
  else echo none
  fi
}

choose_profile() {
  step "Detecting the desktop"
  local session="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-${DESKTOP_SESSION:-}}}"
  info "running session: ${session:-none detected (tty or ssh)}"
  local found=() w
  for w in niri Hyprland i3 gnome-shell plasmashell; do command -v "$w" >/dev/null && found+=("$w"); done
  [ -d "$HOME/.local/share/omarchy" ] && found+=(omarchy)
  info "installed: ${found[*]:-no known window manager or desktop}"

  if [ -z "$PROFILE" ]; then
    PROFILE=$(detect_profile)
    if [ "$MODE" = install ] && (( ! DRY_RUN )) && [ -r /dev/tty ]; then
      local a
      read -r -p "  Profile [${PROFILES[*]}] (Enter for $PROFILE): " a </dev/tty || true
      PROFILE=${a:-$PROFILE}
    fi
  fi
  [[ " ${PROFILES[*]} " == *" $PROFILE "* ]] || die "unknown profile '$PROFILE' (choose from: ${PROFILES[*]})"
  if [ "$PROFILE" = omarchy ] && [[ " $ADD " == *" hypr "* ]]; then
    die "the hypr package is a standalone Hyprland setup and must not be stowed on Omarchy"
  fi

  local defaults all_wm p
  defaults=$(sed -n 's/^DEFAULT_PACKAGES *:= *//p' "$REPO/Makefile")
  all_wm=" ${PROFILE_PKGS[*]} "
  PKGS=()
  for p in $defaults; do [[ $all_wm == *" $p "* ]] || PKGS+=("$p"); done
  for p in ${PROFILE_PKGS[$PROFILE]} $ADD; do
    [ -d "$REPO/$p" ] || die "no package directory '$p' in $REPO"
    [[ " ${PKGS[*]} " == *" $p "* ]] || PKGS+=("$p")
  done
  ok "profile: $PROFILE"
  info "packages: ${PKGS[*]}"
}

# --- links and conflicts ---------------------------------------------------

# Dry-run stow for the given packages with the same flags the Makefile uses.
stow_preview() {
  local plain=() folded=() p
  for p; do if is_folded "$p"; then folded+=("$p"); else plain+=("$p"); fi; done
  if (( ${#plain[@]} )); then stow -n -v -d "$REPO" -t "$TARGET" --no-folding -S "${plain[@]}" 2>&1 || true; fi
  if (( ${#folded[@]} )); then stow -n -v -d "$REPO" -t "$TARGET" -S "${folded[@]}" 2>&1 || true; fi
}

# Paths (relative to TARGET) that block stowing the given packages.
conflicts() {
  {
    stow_preview "$@" | sed -nE \
      -e 's/.*over existing target (.+) since .*/\1/p' \
      -e 's/.*existing target is not owned by stow: (.+)$/\1/p' \
      -e 's/.*existing target is neither a link nor a directory: (.+)$/\1/p'
    # A folded package's directory must become one symlink, so an existing real
    # directory is replaced as a whole (otherwise stow links files inside it).
    local p
    for p; do
      is_folded "$p" || continue
      if [ "$p" = voxtype ] && [ -d "$TARGET/.config/voxtype" ] && [ ! -L "$TARGET/.config/voxtype" ]; then
        echo .config/voxtype
      fi
    done
  } | sort -u | awk '{ for (i = 1; i <= n; i++) if (index($0, kept[i] "/") == 1) next; kept[++n] = $0; print }'
}

# --- 3. backup -------------------------------------------------------------

backup_paths() {
  (( $# )) || return 0
  local rel
  for rel; do
    [ -e "$TARGET/$rel" ] || [ -L "$TARGET/$rel" ] || continue
    if (( DRY_RUN )); then info "[dry-run] would back up $TARGET/$rel"; continue; fi
    mkdir -p "$BACKUP_DIR"
    (cd "$TARGET" && cp -a --parents -- "$rel" "$BACKUP_DIR/")
    if [ -L "$TARGET/$rel" ]; then
      printf '%s -> %s\n' "$rel" "$(readlink "$TARGET/$rel")" >>"$BACKUP_DIR/MANIFEST"
    else
      printf '%s\n' "$rel" >>"$BACKUP_DIR/MANIFEST"
    fi
  done
  (( DRY_RUN )) && return 0
  tar -C "$BACKUP_ROOT" -czf "$BACKUP_ROOT/$STAMP.tar.gz" "$STAMP"
  tar -tzf "$BACKUP_ROOT/$STAMP.tar.gz" >/dev/null || die "backup archive failed verification; nothing was changed"
}

backed_up() {
  [ -f "$BACKUP_DIR/MANIFEST" ] &&
    awk -v p="$1" '$0 == p || index($0, p " -> ") == 1 { found = 1 } END { exit !found }' "$BACKUP_DIR/MANIFEST"
}

do_backup() {
  step "Backing up files the packages would replace"
  mapfile -t CONFLICTS < <(conflicts "${PKGS[@]}")
  if (( ! ${#CONFLICTS[@]} )); then ok "nothing to back up: no existing files are in the way"; return; fi
  local rel
  for rel in "${CONFLICTS[@]}"; do info "$TARGET/$rel"; done
  backup_paths "${CONFLICTS[@]}"
  (( DRY_RUN )) || ok "copied to $BACKUP_DIR and archived as $BACKUP_ROOT/$STAMP.tar.gz"
  info "originals stay in place until the stow step, which asks first"
}

# --- 4. apps ---------------------------------------------------------------

dep_present() {
  # brightnessctl only drives the keyboard backlight keys. Skip it when there is no
  # keyboard backlight, or on ASUS, where asus-wmi handles those keys in the kernel.
  if [ "$1" = brightnessctl ]; then
    compgen -G '/sys/class/leds/*::kbd_backlight' >/dev/null || return 0
    [ -e '/sys/class/leds/asus::kbd_backlight' ] && return 0
  fi
  case $2 in
    -) pacman -T "$1" >/dev/null 2>&1 ;;
    /*) [ -e "$2" ] ;;
    *) command -v "$2" >/dev/null 2>&1 ;;
  esac
}

check_deps() {
  step "Checking the apps these packages need"
  MISS_REQ=0 MISS_REPO=() MISS_AUR=() MISS_MANUAL=()
  local -A seen=() want=()
  local p pkg src name check need note what line
  for p in core "${PKGS[@]}"; do want[$p]=1; done
  declare -A lines=()
  while read -r pkg src name check need note; do
    [[ -z $pkg || $pkg == \#* ]] && continue
    [ -n "${want[$pkg]:-}" ] || continue
    dep_present "$name" "$check" && continue
    what=$name; [ "$src" = manual ] && what=$check
    line="$what ($( [ "$need" = req ] && echo required || echo optional ), $src)${note:+ - $note}"
    lines[$pkg]+="$need|$line"$'\n'
    [ "$need" = req ] && MISS_REQ=$((MISS_REQ + 1))
    [ -n "${seen[$src:$what]:-}" ] && continue
    seen[$src:$what]=1
    case $src in
      pacman) MISS_REPO+=("$name") ;;
      aur) MISS_AUR+=("$name") ;;
      manual) MISS_MANUAL+=("$check: ${note:-see the vendor site}") ;;
    esac
  done <"$DEPS_FILE"

  for p in core "${PKGS[@]}"; do
    if [ -z "${lines[$p]:-}" ]; then ok "$p"; continue; fi
    while IFS='|' read -r need line; do
      [ -n "$line" ] || continue
      if [ "$need" = req ]; then bad "$p: missing $line"; else warn "$p: missing $line"; fi
    done <<<"${lines[$p]}"
  done
  if (( MISS_REQ )); then warn "$MISS_REQ required app(s) missing; those configs will not work until installed"
  else ok "every required app is installed"; fi
}

install_deps() {
  local repo=("${MISS_REPO[@]}") aur=() n helper=""
  # An "aur" package may still ship in a configured repo (CachyOS, chaotic-aur).
  for n in "${MISS_AUR[@]}"; do
    if pacman -Si "$n" >/dev/null 2>&1; then repo+=("$n"); else aur+=("$n"); fi
  done
  (( ${#repo[@]} + ${#aur[@]} + ${#MISS_MANUAL[@]} )) || return 0
  step "Installing missing apps"
  if (( ${#repo[@]} )); then
    info "from your configured pacman repos: ${repo[*]}"
    if confirm "Install these with sudo pacman -S --needed?"; then
      run sudo pacman -S --needed "${repo[@]}" || warn "pacman failed; continuing without them"
    fi
  fi
  if (( ${#aur[@]} )); then
    info "only in the AUR (community-maintained, review each PKGBUILD):"
    for n in "${aur[@]}"; do info "  $n  https://aur.archlinux.org/packages/$n"; done
    command -v paru >/dev/null && helper=paru
    [ -z "$helper" ] && command -v yay >/dev/null && helper=yay
    if [ -n "$helper" ]; then
      if confirm "Build these from the AUR with $helper (it shows each PKGBUILD first)?"; then
        run "$helper" -S --needed "${aur[@]}" || warn "$helper failed; continuing without them"
      fi
    else
      warn "no AUR helper (paru or yay) found; install these yourself if you want them"
    fi
  fi
  if (( ${#MISS_MANUAL[@]} )); then
    info "installed by their vendors' own installers (run these yourself):"
    for n in "${MISS_MANUAL[@]}"; do info "  $n"; done
  fi
}

# --- 5. stow ---------------------------------------------------------------

do_stow() {
  step "Linking the packages"
  # agents-sync regenerates committed files and links skills into $HOME itself,
  # so it only runs for a real install, and a failure does not block stowing.
  if [[ " ${PKGS[*]} " == *" agents "* ]] && [ "$TARGET" = "$HOME" ]; then
    if ! command -v bun >/dev/null; then
      warn "bun is missing, so agents-sync was skipped (its committed output is used as is)"
    elif ! run make -C "$REPO" agents-sync; then
      warn "agents-sync failed (see above); continuing with the committed output"
    fi
  fi
  mapfile -t CONFLICTS < <(conflicts "${PKGS[@]}")
  if (( ${#CONFLICTS[@]} )); then
    info "these existing paths are replaced by links (all are in the backup):"
    local rel
    for rel in "${CONFLICTS[@]}"; do
      info "$TARGET/$rel"
      (( DRY_RUN )) || backed_up "$rel" || backup_paths "$rel"   # appeared after the backup step
    done
    (( DRY_RUN )) || confirm "Remove them and link the dotfiles?" || { warn "stow skipped; nothing was removed"; return; }
    for rel in "${CONFLICTS[@]}"; do
      [[ -n $rel && $rel != /* && $rel != *..* ]] || die "refusing to remove suspicious path '$rel'"
      run rm -rf -- "${TARGET:?}/$rel"
    done
  elif (( ! DRY_RUN )) && ! confirm "Link ${#PKGS[@]} packages into $TARGET?"; then
    warn "stow skipped"; return
  fi
  run make -C "$REPO" stow PKG="${PKGS[*]}" TARGET="$TARGET"
  (( DRY_RUN )) || ok "linked: ${PKGS[*]}"
}

# --- 6. system files and next steps ---------------------------------------

install_system_file() {  # $1 label, $2 repo file, $3 destination, $4 mode, rest: follow-up command
  local label=$1 src=$REPO/$2 dst=$3 mode=$4; shift 4
  if cmp -s "$src" "$dst" 2>/dev/null; then ok "$label already installed"; return; fi
  if confirm "Install $label ($dst, needs sudo)?"; then
    run sudo install -Dm"$mode" "$src" "$dst"
    (( $# )) && run sudo "$@"
  fi
}

system_extras() {
  step "Optional system-wide files"
  if command -v keyd >/dev/null; then
    install_system_file "keyd Caps Lock mapping" keyd/default.conf /etc/keyd/default.conf 644 systemctl enable --now keyd.service
  else
    info "keyd (Caps Lock tap Escape, hold Control): install keyd first, see omarchy/README.md"
  fi
  if command -v udisksctl >/dev/null && command -v notify-send >/dev/null; then
    install_system_file "USB notify script" udev/usb-notify.sh /usr/local/bin/usb-notify.sh 755
    install_system_file "USB notify udev rule" udev/99-usb-notify.rules /etc/udev/rules.d/99-usb-notify.rules 644 udevadm control --reload-rules
  fi
  install_system_file "TCP BBR congestion control" sysctl/99-bbr.conf /etc/sysctl.d/99-bbr.conf 644 sysctl --system
  info "sddm/ (HiDPI login screen) is tuned to one laptop panel; see docs/NEW-MACHINE.md"
}

next_steps() {
  step "Left for you"
  [ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh || echo zsh)" ] || info "make zsh your login shell: chsh -s \"\$(command -v zsh)\""
  if [[ " ${PKGS[*]} " == *" voxtype "* ]] && command -v voxtype >/dev/null; then
    info "dictation: voxtype setup model (pick small.en), voxtype setup vad, then voxtype setup systemd"
    info "           and systemctl --user enable --now voxtype; check gpu_device with voxtype setup gpu"
  fi
  if [[ " ${PKGS[*]} " == *" scripts "* ]]; then
    info "apps outside pacman (Hype, Disktree, AppImages): run check-app-updates, then update-apps"
    grep -q '^IgnorePkg.*hype' /etc/pacman.conf 2>/dev/null ||
      info "pin Hype and Disktree: add 'IgnorePkg = hype disktree-bin' to /etc/pacman.conf"
  fi
  info "log out and back in so the shell and desktop pick up the new configs"
  info "re-run any time: make check"
}

# --- check mode ------------------------------------------------------------

link_report() {
  step "Link status"
  UNLINKED=0
  local p out links confl
  for p in "${PKGS[@]}"; do
    out=$(stow_preview "$p")
    # A symlink stored in a package shows as UNLINK + LINK "(reverts previous action)".
    links=$(grep '^LINK:' <<<"$out" | grep -vc 'reverts previous action' || true)
    confl=$(conflicts "$p" | wc -l)
    if (( confl )); then bad "$p: $confl existing file(s) in the way (bootstrap backs them up)"; UNLINKED=$((UNLINKED + 1))
    elif (( links )); then warn "$p: $links link(s) missing (make stow-$p)"; UNLINKED=$((UNLINKED + 1))
    else ok "$p"; fi
  done
}

# --- main ------------------------------------------------------------------

check_system
choose_profile
if [ "$MODE" = check ]; then
  link_report
  check_deps
  echo
  (( UNLINKED == 0 && MISS_REQ == 0 )) && { ok "all set"; exit 0; }
  warn "$UNLINKED package(s) not fully linked, $MISS_REQ required app(s) missing"
  exit 1
fi

(( DRY_RUN )) && warn "dry run: nothing will be changed"
do_backup
check_deps
install_deps
do_stow
system_extras
next_steps
