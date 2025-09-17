##!/bin/bash
CHROME_ON_WS6=$(i3-msg -t get_workspaces | jq '.[] | select(.name=="6" and .focused==false) | .name' | wc -l)
YT_URL="https://music.youtube.com"

if [ "$CHROME_ON_WS6" -gt 0 ]; then
  # Just switch to workspace 6
  i3-msg 'workspace 6'
else
  # Switch to workspace 6 and launch Chrome
  i3-msg 'workspace 6'
  sleep 0.2
  exec google-chrome-stable --profile-directory="Profile 1" --app="${YT_URL}"
fi
