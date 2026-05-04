---
description: Suggest branch names using GPT-5.4 nano as fallback.
agent: pr-writer
model: openai/gpt-5.4-nano
---
Context:
!`git status --short`
!`git diff --stat`

Suggest 3 short branch names in kebab-case.
