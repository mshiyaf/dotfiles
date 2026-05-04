---
description: Suggest short branch names from current worktree context.
agent: pr-writer
---
Context:
!`git status --short`
!`git diff --stat`
!`git branch --show-current`
!`git log --oneline -5`

Suggest 5 branch names. Use lowercase hyphenated names. Avoid stack-specific prefixes unless evident from the diff. Include one recommended option.
