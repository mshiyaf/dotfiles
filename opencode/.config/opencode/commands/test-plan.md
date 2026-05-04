---
description: Create a practical test plan for a change or feature.
agent: tester
---
Use the test-writer skill.

Target:
$ARGUMENTS

Context:
!`git status --short`
!`git diff --stat`
!`git diff`

Create a concise test plan with unit, integration, manual, edge-case, and regression checks. Do not edit unless asked.
