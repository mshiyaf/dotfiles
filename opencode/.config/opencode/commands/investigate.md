---
description: Investigate a bug or failure systematically before proposing fixes.
agent: debugger
---
Use systematic-debugging, debugging, grounding, code-review, and test-writer skills when relevant.

Issue:
$ARGUMENTS

Context:
!`git status --short`
!`git branch --show-current`
!`git log --oneline -10`

Investigate before fixing:
- Reproduce or identify the failing path if possible.
- Gather evidence from code, logs, tests, or diffs.
- Trace the smallest relevant data/control flow.
- State the root cause and confidence level.
- Propose the smallest safe fix and verification command.
- Stop and reassess after three failed fix hypotheses.

Do not edit files unless the user explicitly asks you to fix it after the investigation.
