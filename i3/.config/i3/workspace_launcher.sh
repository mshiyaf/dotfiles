#!/bin/bash

# Function to check if a process is running
process_running() {
  pgrep -f "$1" >/dev/null
}

# Chrome - just check if the main process is running
if ! pgrep -x "chrome" >/dev/null; then
  google-chrome-stable --profile-directory="Profile 2" &
fi

# Kitty Terminal
if ! process_running "kitty"; then
  kitty &
fi

# DBeaver
if ! process_running "dbeaver"; then
  dbeaver &
fi

# Postman
if ! process_running "postman"; then
  postman &
fi

# Mattermost
if ! process_running "mattermost"; then
  mattermost-desktop &
fi

# Anydesk
if ! process_running "anydesk"; then
  anydesk &
fi
