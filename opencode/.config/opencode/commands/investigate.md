---
description: Investigate a bug or failure systematically before proposing fixes.
agent: debugger
---
Use systematic-debugging, debugging, grounding, code-review, and test-writer skills when relevant.
Use the investigate skill.

Issue:
$ARGUMENTS

Context:
!`git status --short`
!`git branch --show-current`
!`git log --oneline -10`

Do not edit files unless the user explicitly asks you to fix it after the investigation.
