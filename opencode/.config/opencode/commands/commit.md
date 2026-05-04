---
description: Draft a concise commit message from staged changes.
agent: pr-writer
model: opencode/minimax-m2.5-free
---
Use the git-commit skill.

Context:
!`git status --short`
!`git diff --cached --stat`
!`git diff --cached`
!`git log --oneline -10`

Draft one commit message only. Do not commit. If nothing is staged, say so.
