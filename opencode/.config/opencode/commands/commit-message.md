---
description: Draft a concise commit message from staged changes.
agent: pr-writer
---
Use the git-commit skill.

Context:
!`git status --short`
!`git diff --cached --stat`
!`git diff --cached`
!`git log --oneline -10`

Draft one commit message only. Do not stage files and do not run `git commit`. If nothing is staged, say so.
