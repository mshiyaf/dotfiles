---
description: Debug failing tests using GPT-5.3 codex as fallback.
agent: debugger
model: openai/gpt-5.3-codex
---
Use the debugging skill.

Context:
!`git status --short`
!`git diff`

Investigate failures root-cause first. Propose minimal fixes.
