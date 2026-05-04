---
description: Long-context review using DeepSeek V4 Pro as fallback to GLM.
agent: reviewer
model: fireworks-ai/accounts/fireworks/models/deepseek-v4-pro
---
Use the code-review skill.

Context:
!`git status --short`
!`git diff --stat`
!`git diff`

Review across the full diff. Findings first.
