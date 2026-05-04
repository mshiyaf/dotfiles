---
description: Review staged changes using GLM-5.1 as fallback.
agent: reviewer
model: fireworks-ai/accounts/fireworks/models/glm-5p1
---
Use the code-review skill.

Context:
!`git diff --cached`

Review findings first, ordered by severity. Do not edit files.
