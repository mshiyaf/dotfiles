---
description: Draft a commit message using Kimi K2.5 for higher quality than the default cheap model.
agent: pr-writer
model: kimi-for-coding/k2p5
---
Use the git-commit skill.

Context:
!`git status --short`
!`git diff --cached --stat`
!`git diff --cached`
!`git log --oneline -10`

Draft one commit message only. Do not commit. If nothing is staged, say so.
