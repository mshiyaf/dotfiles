#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

script_path="${BASH_SOURCE[0]}"
base_dir="$HOME/dev/github.com"
gh_search_repo_jq='.[] | [.fullName, (if .isPrivate then "private" else "public" end), (.description // "")] | @tsv'
gh_list_repo_jq='.[] | [.nameWithOwner, (if .isPrivate then "private" else "public" end), (.description // "")] | @tsv'
force_github_flag="/tmp/tmux-sessionizer-force-github-$$"
search_dirs=(
    "$base_dir"/*/*
    "$base_dir/mshiyaf/dotfiles"
)

cleanup() {
    rm -f "$force_github_flag"
}

trap cleanup EXIT

if [[ "${1:-}" == "--github-source" ]]; then
    query="${2:-}"

    if [[ -n "$query" ]]; then
        gh search repos "$query" --limit 100 --json fullName,description,isPrivate --jq "$gh_search_repo_jq" 2>/dev/null || true
    else
        login=$(gh api user --jq .login)
        owners=("$login")

        while IFS= read -r owner; do
            [[ -n "$owner" ]] && owners+=("$owner")
        done < <(gh api user/orgs --jq '.[].login' 2>/dev/null || true)

        for owner in "${owners[@]}"; do
            gh repo list "$owner" --limit 200 --json nameWithOwner,description,isPrivate --jq "$gh_list_repo_jq" 2>/dev/null || true
        done | sort -u
    fi

    exit 0
fi

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
    local selected reload_cmd

    reload_cmd="sleep 0.25; \"$script_path\" --github-source {q}"

    selected=$(fzf \
        --height=55% \
        --reverse \
        --border \
        --disabled \
        --query "$query" \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --accept-nth=1 \
        --prompt="gh > " \
        --header="GitHub search | type to refetch | enter clone | esc back" \
        --input-label=" Query " \
        --list-label=" Loading GitHub repos... " \
        --info=inline-right \
        --bind "start:reload($reload_cmd || true)" \
        --bind "change:change-list-label( Searching GitHub... )+reload($reload_cmd || true)" \
        --bind "result:change-list-label( GitHub results )" \
    ) || return 1

    printf '%s\n' "$selected"
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

    rm -f "$force_github_flag"

    set +e
    result=$(build_local_entries | fzf \
        --height=40% \
        --reverse \
        --border \
        --delimiter=$'\t' \
        --with-nth=2,3 \
        --accept-nth=3 \
        --bind="ctrl-g:execute-silent(sh -c 'printf github > \"$force_github_flag\"')+accept,alt-g:execute-silent(sh -c 'printf github > \"$force_github_flag\"')+accept,f3:execute-silent(sh -c 'printf github > \"$force_github_flag\"')+accept" \
        --print-query \
        --prompt="repo > " \
        --header="tmux sessions | enter local | type owner/repo to clone | enter query to search GitHub | ctrl-g/alt-g/f3 force GitHub search" \
        --preview='dir=$(printf "%s" {} | cut -f3); [[ -d "$dir" ]] && eza --icons --git -l "$dir"' \
        --preview-window=right:40% \
    )
    status=$?
    set -e

    if [[ $status -ne 0 && -z "$result" ]]; then
        return 1
    fi

    mapfile -t PICK_LINES <<< "$result"

    if [[ -f "$force_github_flag" ]]; then
        PICK_KEY="force-github"
        if [[ ${#PICK_LINES[@]} -ge 3 ]]; then
            PICK_QUERY="${PICK_LINES[1]:-}"
            PICK_SELECTION="${PICK_LINES[2]:-}"
        else
            PICK_QUERY="${PICK_LINES[0]:-}"
            PICK_SELECTION="${PICK_LINES[1]:-}"
        fi
    elif [[ ${#PICK_LINES[@]} -ge 3 ]]; then
        PICK_KEY="${PICK_LINES[0]:-}"
        PICK_QUERY="${PICK_LINES[1]:-}"
        PICK_SELECTION="${PICK_LINES[2]:-}"
    else
        PICK_KEY=""
        PICK_QUERY="${PICK_LINES[0]:-}"
        PICK_SELECTION="${PICK_LINES[1]:-}"
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

    if [[ "$PICK_KEY" == "force-github" ]]; then
        repo_ref=$(search_github_repo "$PICK_QUERY") || exit 0
        selected=$(ensure_repo_local "$repo_ref")
    elif [[ -n "$PICK_SELECTION" ]]; then
        selected="$PICK_SELECTION"
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

tmux has-session -t "$selected_name" 2>/dev/null || tmux new-session -ds "$selected_name" -c "$selected"

if [[ -z "${TMUX:-}" ]]; then
    exec tmux attach-session -t "$selected_name"
else
    target_client=$(tmux display-message -p '#{client_tty}' 2>/dev/null || true)
    if [[ -n "$target_client" ]]; then
        tmux switch-client -c "$target_client" -t "$selected_name"
    else
        tmux switch-client -t "$selected_name"
    fi
fi
