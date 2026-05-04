---
description: Review only staged changes before commit.
agent: reviewer
---
Use the code-review skill.

Context:
!`git status --short`
!`git diff --cached --stat`
!`git diff --cached`

Review staged changes only. Findings first. Do not edit files.
