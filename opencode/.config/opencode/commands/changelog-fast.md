---
description: Draft changelog using GPT-5.5 fast as fallback.
agent: pr-writer
model: openai/gpt-5.5-fast
---
Use the release-notes skill.

Context:
!`git log --oneline -50`
!`git diff --stat`
