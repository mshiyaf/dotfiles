---
description: Draft changelog or release notes from commits and diffs.
agent: pr-writer
---
Use the release-notes skill.

Context:
!`git branch --show-current`
!`git log --oneline -30`
!`git diff --stat origin/main...HEAD`

Draft user-facing changelog entries. Group by Added, Changed, Fixed, Removed, Security when applicable. Do not edit files unless explicitly requested.
