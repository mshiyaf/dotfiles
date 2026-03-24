#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

base_dir="$HOME/dev/github.com"
gh_repo_jq='.[] | [.nameWithOwner, (if .isPrivate then "private" else "public" end), (.description // "")] | @tsv'
search_dirs=(
    "$base_dir"/*/*
    "$base_dir/mshiyaf/dotfiles"
)

is_repo_ref() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]
}

collect_local_dirs() {
    local dirs=()
    local dir

    for dir in "${search_dirs[@]}"; do
        [[ -d "$dir" ]] && dirs+=("$dir")
    done

    if [[ ${#dirs[@]} -gt 0 ]]; then
        printf '%s\n' "${dirs[@]}" | sort -u
    fi
}

build_local_entries() {
    local dir owner repo

    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        owner=$(basename "$(dirname "$dir")")
        repo=$(basename "$dir")
        printf 'local\t%s/%s\t%s\n' "$owner" "$repo" "$dir"
    done < <(collect_local_dirs)
}

search_github_repo() {
    local query="${1:-}"
    local entries selected login

    if [[ -n "$query" ]]; then
        entries=$(gh search repos "$query" --limit 100 --json nameWithOwner,description,isPrivate --jq "$gh_repo_jq")
    else
        login=$(gh api user --jq .login)
        entries=$(gh repo list "$login" --limit 100 --json nameWithOwner,description,isPrivate --jq "$gh_repo_jq")
    fi

    [[ -z "$entries" ]] && return 1

    selected=$(printf '%s\n' "$entries" | fzf \
        --height=50% \
        --reverse \
        --border \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --prompt="gh > " \
        --header="GitHub repos" \
    ) || return 1

    printf '%s\n' "${selected%%$'\t'*}"
}

ensure_repo_local() {
    local repo_ref="$1"
    local owner="${repo_ref%%/*}"
    local repo="${repo_ref##*/}"
    local target="$base_dir/$owner/$repo"

    if [[ ! -d "$target" ]]; then
        mkdir -p "$base_dir/$owner"
        gh repo clone "$repo_ref" "$target" >&2
    fi

    printf '%s\n' "$target"
}

pick_repo() {
    local result status

    set +e
    result=$(build_local_entries | fzf \
        --height=40% \
        --reverse \
        --border \
        --delimiter=$'\t' \
        --with-nth=2,3 \
        --expect=ctrl-g,alt-g \
        --bind='ctrl-g:accept,alt-g:accept' \
        --print-query \
        --prompt="repo > " \
        --header="tmux sessions | enter local | type owner/repo to clone | type anything else + enter to search GitHub" \
        --preview='dir=$(printf "%s" {} | cut -f3); [[ -d "$dir" ]] && eza --icons --git -l "$dir"' \
        --preview-window=right:40% \
    )
    status=$?
    set -e

    if [[ $status -ne 0 && -z "$result" ]]; then
        return 1
    fi

    mapfile -t PICK_LINES <<< "$result"
    PICK_KEY="${PICK_LINES[0]:-}"
    PICK_QUERY="${PICK_LINES[1]:-}"
    PICK_SELECTION="${PICK_LINES[2]:-}"

    if [[ $status -eq 1 && -z "$PICK_SELECTION" ]]; then
        PICK_KEY=""
        PICK_QUERY="${PICK_LINES[0]:-}"
    fi
}

if [[ $# -eq 1 ]]; then
    if [[ -d "$1" ]]; then
        selected="$1"
    elif is_repo_ref "$1"; then
        selected=$(ensure_repo_local "$1")
    else
        exit 1
    fi
else
    pick_repo || exit 0

    if [[ "$PICK_KEY" == "ctrl-g" || "$PICK_KEY" == "alt-g" ]]; then
        repo_ref=$(search_github_repo "$PICK_QUERY") || exit 0
        selected=$(ensure_repo_local "$repo_ref")
    elif [[ -n "$PICK_SELECTION" ]]; then
        selected="${PICK_SELECTION##*$'\t'}"
    elif is_repo_ref "$PICK_QUERY"; then
        selected=$(ensure_repo_local "$PICK_QUERY")
    elif [[ -n "$PICK_QUERY" ]]; then
        repo_ref=$(search_github_repo "$PICK_QUERY") || exit 0
        selected=$(ensure_repo_local "$repo_ref")
    else
        exit 0
    fi
fi

[[ -z "$selected" ]] && exit 0

parent=$(basename "$(dirname "$selected")")
repo=$(basename "$selected")
selected_name="${parent}/${repo}"
selected_name="${selected_name//\//_}"
selected_name="${selected_name//./_}"
selected_name="${selected_name//:/_}"

tmux new-session -ds "$selected_name" -c "$selected" 2>/dev/null

if [[ -z "${TMUX:-}" ]]; then
    tmux attach-session -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
