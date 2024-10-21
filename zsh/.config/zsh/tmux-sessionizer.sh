#!/usr/bin/env bash

# decalare the files to search for
file_list=(~/notes ~/code ~/code/dotfiles ~/dev/texol ~/dev/sprdh ~/dev/personal)

# Create a new array to store valid directories
valid_files=()

# Check if the directories exist and add to the valid_files list
for file in "${file_list[@]}"; do
  if [[ -d $file ]]; then
    valid_files+=("$file")
  fi
done

if [[ $# -eq 1 ]]; then
  selected=$1
else
  selected=$(find "${valid_files[@]}" -mindepth 1 -maxdepth 2 -type d | fzf)
fi

if [[ -z $selected ]]; then
  exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)
if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
  tmux new-session -s $selected_name -c $selected
  exit 0
fi

if ! tmux has-session -t $selected_name 2>/dev/null; then
  tmux new-session -ds $selected_name -c $selected
fi

if [[ -z $TMUX ]]; then
  tmux attach-session -t $selected_name
else
  tmux switch-client -t $selected_name
fi
