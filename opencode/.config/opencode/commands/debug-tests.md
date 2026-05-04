---
description: Debug failing tests with root-cause-first investigation.
agent: debugger
---
Use the debugging skill.

Context:
!`git status --short`
!`git diff --stat`

Run the relevant test command if obvious. If not obvious, identify candidate test commands from project files and ask before running.

Test command placeholder:
$ARGUMENTS

Reproduce, identify root cause, and propose or apply the smallest targeted fix.
