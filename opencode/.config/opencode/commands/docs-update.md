---
description: Update docs or README from current changes.
agent: docs-writer
---
Use the documentation skill.

Context:
!`git status --short`
!`git diff --stat`
!`git diff`
!`git log --oneline -10`

Update relevant documentation only if needed. If no doc update is warranted, explain why.
