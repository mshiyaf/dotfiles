---
description: Review across many files or a long diff using a long-context model.
agent: reviewer
model: fireworks-ai/accounts/fireworks/models/glm-5p1
---
Use the code-review skill.

Context:
!`git status --short`
!`git diff --stat`
!`git diff`

Review across the full diff. Findings first, grouped by file or subsystem.
Call out cross-file regressions, contract drift, and consistency gaps a normal
single-file review would miss. Do not edit files.
