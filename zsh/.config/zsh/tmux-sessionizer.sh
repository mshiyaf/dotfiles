#!/usr/bin/env bash

# Directories to search for projects (2 levels deep)
search_dirs=(
    ~/dev/github.com/*/*
    ~/dev/github.com/mshiyaf/dotfiles
)

# Collect valid directories
dirs=()
for d in "${search_dirs[@]}"; do
    [[ -d "$d" ]] && dirs+=("$d")
done

if [[ $# -eq 1 ]]; then
    selected="$1"
else
    selected=$(printf '%s\n' "${dirs[@]}" | fzf \
        --height=40% \
        --reverse \
        --border \
        --prompt="  " \
        --header="tmux sessions" \
        --preview="eza --icons --git -l {}" \
        --preview-window=right:40% \
    ) || exit 0
fi

[[ -z "$selected" ]] && exit 0

# Session name: org/repo (e.g. texol-world-iCohort/almawasil-tenant-server → texol/almawasil)
parent=$(basename "$(dirname "$selected")")
repo=$(basename "$selected")
selected_name="${parent}/${repo}"
# tmux doesn't allow dots or colons in session names
selected_name="${selected_name//./_}"
selected_name="${selected_name//:/_}"

# Not in tmux and tmux not running → start fresh
if [[ -z "$TMUX" ]] && ! pgrep -x tmux &>/dev/null; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

# Create session if it doesn't exist
if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

# Attach or switch
if [[ -z "$TMUX" ]]; then
    tmux attach-session -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
