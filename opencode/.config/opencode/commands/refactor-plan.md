---
description: Plan a safe refactor with sequencing and verification.
agent: refactor-planner
model: kimi-for-coding/k2p6
---
Use the refactor-planner skill.

Target:
$ARGUMENTS

Context:
!`git status --short`
!`git diff --stat`

Create a safe refactor plan. Separate mechanical changes from behavior changes. Include tests, rollout, and rollback.
