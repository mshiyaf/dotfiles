---
description: Second opinion on the current diff from the Claude CLI (uses your Claude sub).
agent: reviewer
---
Hand the current diff to Claude for an independent second opinion via the `claude` CLI.
This uses the local Claude subscription - no API provider is configured in OpenCode.

Diff under review:
!`git diff --stat`

Claude's second opinion:
!`git diff | claude -p "You are a senior reviewer giving a second opinion on this diff. Findings first, severity-tagged (Critical/Important/Minor), one line of context each. Focus on bugs, regressions, security, and data safety. No prose, no diff summary." --output-format text 2>&1 || echo "(claude CLI unavailable or errored - is 'claude' on PATH and authenticated?)"`

Present Claude's findings as-is, then add anything you'd flag that Claude missed.
Do not auto-apply fixes - the user decides.
