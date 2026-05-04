---
description: Draft a PR title and body from branch changes.
agent: pr-writer
---
Use the pull-request skill.

Context:
!`git branch --show-current`
!`git status --short`
!`git diff --stat`
!`git log --oneline --decorate -20`
!`git diff --stat origin/main...HEAD`

Draft:
Title
Summary
Test plan
Risks
Reviewer notes

Do not create the PR.
