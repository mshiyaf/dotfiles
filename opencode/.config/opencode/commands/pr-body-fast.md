---
description: Draft PR body using GPT-5.5 fast as fallback.
agent: pr-writer
model: openai/gpt-5.5-fast
---
Use the pull-request skill.

Context:
!`git log --oneline -20`
!`git diff --stat`
!`git diff`
