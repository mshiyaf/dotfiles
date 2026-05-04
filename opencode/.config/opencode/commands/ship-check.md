---
description: Final readiness review before merge or release.
agent: reviewer
---
Use code-review, security-review, test-writer, and release-notes skills when relevant.

Context:
!`git branch --show-current`
!`git status --short`
!`git diff --stat`
!`git diff`
!`git diff --cached`
!`git log --oneline -20`

Check correctness, tests, docs, migrations, security, release notes, and rollback risk. Findings first. Do not edit files.
