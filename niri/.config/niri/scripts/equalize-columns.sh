#!/bin/sh
# Equalize the width of all columns in the currently focused niri workspace.
# Counts the columns in the active workspace and sets each to an equal share.

ncols=$(niri msg --json windows | python3 -c '
import json, sys
wins = json.load(sys.stdin)
ws = next((w["workspace_id"] for w in wins if w.get("is_focused")), None)
cols = {
    w["layout"]["pos_in_scrolling_layout"][0]
    for w in wins
    if w["workspace_id"] == ws
    and not w.get("is_floating")
    and w["layout"].get("pos_in_scrolling_layout")
}
print(len(cols))
')

[ -z "$ncols" ] && exit 1
[ "$ncols" -lt 1 ] && exit 0

width=$(awk "BEGIN { printf \"%.3f\", 100 / $ncols }")

niri msg action focus-column-first
i=0
while [ "$i" -lt "$ncols" ]; do
    niri msg action set-column-width "${width}%"
    niri msg action focus-column-right
    i=$((i + 1))
done
