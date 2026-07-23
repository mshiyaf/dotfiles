#!/usr/bin/env bash
#
# CommandCode PreToolUse guard for bounded Crew / Gate runs.
#
# Registered globally by ~/.commandcode/settings.json for the "shell" matcher.
# It ONLY constrains runs that Crew and Gate mark with CREW_MANAGED=1; interactive
# sessions never set it, so the hook is a no-op there and you can still push,
# sudo, etc. by hand.
#
# Why it exists: CommandCode's headless (-p) mode cannot edit or commit without
# --yolo, so a tasked crewmate must run with --yolo. Under --yolo this deny-list
# is the ONLY thing bounding the run, so the hook fails CLOSED: any parse or
# runtime error denies the tool call rather than letting it through. Crew and Gate
# additionally refuse to launch if this script is missing (see require_commandcode_guard).
#
# Contract (see https://commandcode.ai/docs/hooks): a PreToolUse hook denies a call
# by printing a JSON object with permissionDecision:"deny" and exiting 0.
set -euo pipefail

# Not a managed (Crew/Gate) run -> never interfere.
[ "${CREW_MANAGED:-}" = "1" ] || exit 0

deny() {
	printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
		"$(printf '%s' "${1:-crew guard: blocked}" | jq -Rs .)"
	exit 0
}

# Fail closed: any error below denies instead of proceeding.
trap 'deny "crew guard: internal error - denying to stay bounded"' ERR

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // .tool_input.shell_command // ""')

# Outward-facing or destructive operations a bounded crewmate must never run.
# Crewmates commit on their own branch but never push, escalate privileges,
# rewrite history, wipe the tree, or run pipe-to-shell installers.
danger='(^|[;&|[:space:]])sudo([[:space:]]|$)'
danger+='|git[[:space:]]+push'
danger+='|git[[:space:]]+reset[[:space:]]+--hard'
danger+='|git[[:space:]]+clean'
danger+='|(^|[;&|[:space:]])rm[[:space:]]+-[a-zA-Z]*[rRf][a-zA-Z]*[[:space:]]'
danger+='|:\(\)[[:space:]]*\{'
danger+='|curl[^|]*\|[[:space:]]*(ba)?sh'

if printf '%s' "$cmd" | grep -qE "$danger"; then
	deny "crew guard blocks outward/destructive command: $(printf '%s' "$cmd" | cut -c1-100)"
fi

exit 0
