#!/usr/bin/env bash

# Herdr sessionizer: fuzzy-jump to projects, workspaces, and agents.
# Mixes our tmux-sessionizer (local repos + GitHub search/clone via gh) with
# ideas from andrewchng/herdr-sessionizer and thanhdat77/herdr-navigator:
# open workspaces and running agents are jump targets, projects open as
# new workspaces, GitHub search is behind an explicit ctrl-g.

set -euo pipefail
shopt -s nullglob

script_path="${BASH_SOURCE[0]}"
base_dir="$HOME/dev/github.com"
gh_search_repo_jq='.[] | [.fullName, (if .isPrivate then "private" else "public" end), (.description // "")] | @tsv'
gh_list_repo_jq='.[] | [.nameWithOwner, (if .isPrivate then "private" else "public" end), (.description // "")] | @tsv'
force_github_flag="/tmp/herdr-sessionizer-force-github-$$"
search_dirs=(
    "$base_dir"/*/*
    "$base_dir/mshiyaf/dotfiles"
)

c_reset=$'\033[0m'
c_green=$'\033[32m'
c_yellow=$'\033[33m'
c_red=$'\033[31m'
c_cyan=$'\033[36m'
c_dim=$'\033[2m'

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

if ! herdr workspace list >/dev/null 2>&1; then
    echo "herdr server not reachable; start herdr first." >&2
    exit 1
fi

is_repo_ref() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]
}

workspace_label() {
    local dir="${1%/}"
    local repo="${dir##*/}"
    local parent="${dir%/*}"
    local name="${parent##*/}/$repo"
    name="${name//\//_}"
    name="${name//./_}"
    name="${name//:/_}"
    printf '%s\n' "$name"
}

herdr_workspaces_tsv() {
    herdr workspace list 2>/dev/null \
        | jq -r '.result.workspaces[] | [.workspace_id, (.label // ""), (.tab_count // 0), (.pane_count // 0)] | @tsv'
}

herdr_pane_cwds_tsv() {
    herdr pane list 2>/dev/null \
        | jq -r '.result.panes[] | [.workspace_id, (.foreground_cwd // .cwd // "")] | @tsv'
}

herdr_agents_tsv() {
    herdr agent list 2>/dev/null \
        | jq -r '.result.agents[] | [.terminal_id, (.agent // "agent"), (.agent_status // "unknown"), .workspace_id, (.terminal_title_stripped // "")] | @tsv'
}

find_workspace_id() {
    local label="$1" dir="$2"
    local id ws_label ws_cwd

    while IFS=$'\t' read -r id ws_label _; do
        if [[ "$ws_label" == "$label" ]]; then
            printf '%s\n' "$id"
            return 0
        fi
    done < <(herdr_workspaces_tsv)

    while IFS=$'\t' read -r id ws_cwd; do
        if [[ "$ws_cwd" == "$dir" ]]; then
            printf '%s\n' "$id"
            return 0
        fi
    done < <(herdr_pane_cwds_tsv)

    return 1
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

agent_status_color() {
    case "$1" in
        working) printf '%s' "$c_yellow" ;;
        blocked) printf '%s' "$c_red" ;;
        done) printf '%s' "$c_green" ;;
        idle) printf '%s' "$c_cyan" ;;
        *) printf '%s' "$c_dim" ;;
    esac
}

# Rows are `kind \t name \t detail \t target` where target is a project
# path, `ws:<workspace_id>`, or `agent:<terminal_id>`.
# Rows stream to fzf as they are ready: herdr-backed rows (workspaces,
# agents) print first, the local project scan fills in below them.
build_entries() {
    local dir owner repo rest label id ws_label tabs panes cwd wsid
    local tid agent status title color
    local local_lines=""
    declare -A open_labels=() open_cwds=() ws_labels=() ws_meta=() ws_used=()

    while IFS=$'\t' read -r id ws_label tabs panes; do
        [[ -z "$id" ]] && continue
        ws_labels["$id"]="$ws_label"
        ws_meta["$id"]="${tabs} tabs · ${panes} panes"
        [[ -n "$ws_label" ]] && open_labels["$ws_label"]="$id"
    done < <(herdr_workspaces_tsv)

    while IFS=$'\t' read -r id cwd; do
        [[ -n "$cwd" ]] && open_cwds["$cwd"]="$id"
    done < <(herdr_pane_cwds_tsv)

    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        dir="${dir%/}"
        repo="${dir##*/}"
        rest="${dir%/*}"
        owner="${rest##*/}"
        label="${owner}_${repo}"
        label="${label//./_}"
        label="${label//:/_}"
        wsid="${open_labels[$label]:-${open_cwds[$dir]:-}}"
        if [[ -n "$wsid" ]]; then
            ws_used["$wsid"]=1
            printf '%s\t%s\t\t%s\n' "${c_green}open${c_reset}" "$owner/$repo" "$dir"
        else
            local_lines+="${c_dim}local${c_reset}"$'\t'"$owner/$repo"$'\t'$'\t'"$dir"$'\n'
        fi
    done < <(collect_local_dirs)

    # Workspaces with no matching local project (worktrees, manual ones).
    for id in $(printf '%s\n' "${!ws_labels[@]}" | sort); do
        [[ -n "${ws_used[$id]:-}" ]] && continue
        printf '%s\t%s\t%s\t%s\n' "${c_green}open${c_reset}" "${ws_labels[$id]:-$id}" \
            "${c_dim}${ws_meta[$id]}${c_reset}" "ws:$id"
    done

    while IFS=$'\t' read -r tid agent status wsid title; do
        [[ -z "$tid" ]] && continue
        color=$(agent_status_color "$status")
        printf '%s\t%s\t%s\t%s\n' "${color}${status}${c_reset}" "${agent} · ${ws_labels[$wsid]:-$wsid}" \
            "${c_dim}${title}${c_reset}" "agent:$tid"
    done < <(herdr_agents_tsv)

    printf '%s' "$local_lines"
}

search_github_repo() {
    local query="${1:-}"
    local selected reload_cmd

    reload_cmd="sleep 0.25; \"$script_path\" --github-source {q}"

    selected=$(fzf \
        --height=100% \
        --reverse \
        --border \
        --disabled \
        --query "$query" \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --accept-nth=1 \
        --prompt="gh > " \
        --header="type to search · enter clone · esc back" \
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

pick_target() {
    local result status

    rm -f "$force_github_flag"

    set +e
    result=$(build_entries | fzf \
        --height=100% \
        --reverse \
        --border \
        --ansi \
        --delimiter=$'\t' \
        --with-nth=1,2,3 \
        --accept-nth=4 \
        --bind="ctrl-g:execute-silent(sh -c 'printf github > \"$force_github_flag\"')+accept,alt-g:execute-silent(sh -c 'printf github > \"$force_github_flag\"')+accept,f3:execute-silent(sh -c 'printf github > \"$force_github_flag\"')+accept" \
        --print-query \
        --prompt="jump > " \
        --header="enter jump · owner/repo clones · ctrl-g github" \
        --preview='t={4}; case "$t" in
            agent:*) herdr agent read "${t#agent:}" --lines 60 2>/dev/null | jq -r ".result.read.text // \"(no agent output)\"";;
            ws:*) herdr workspace get "${t#ws:}" 2>/dev/null | jq -C .result.workspace;;
            *) [ -d "$t" ] && eza --icons --git -l "$t";;
        esac' \
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
    pick_target || exit 0

    if [[ "$PICK_KEY" == "force-github" ]]; then
        repo_ref=$(search_github_repo "$PICK_QUERY") || exit 0
        selected=$(ensure_repo_local "$repo_ref")
    elif [[ -n "$PICK_SELECTION" ]]; then
        selected="$PICK_SELECTION"
    elif is_repo_ref "$PICK_QUERY"; then
        selected=$(ensure_repo_local "$PICK_QUERY")
    else
        exit 0
    fi
fi

[[ -z "$selected" ]] && exit 0

case "$selected" in
    agent:*)
        herdr agent focus "${selected#agent:}" >/dev/null
        exit 0
        ;;
    ws:*)
        herdr workspace focus "${selected#ws:}" >/dev/null
        exit 0
        ;;
esac

selected="${selected%/}"
label=$(workspace_label "$selected")

if ws_id=$(find_workspace_id "$label" "$selected"); then
    herdr workspace focus "$ws_id" >/dev/null
else
    herdr workspace create --cwd "$selected" --label "$label" --focus >/dev/null
fi
