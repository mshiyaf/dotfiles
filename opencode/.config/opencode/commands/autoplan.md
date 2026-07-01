---
description: Produce a gstack-style end-to-end implementation plan without editing files.
agent: architect
---
Use api-design, code-review, test-writer, security-review, database-review, and refactor-planner skills when relevant.

Goal:
$ARGUMENTS

Context:
!`git status --short`
!`git branch --show-current`
!`git log --oneline -10`
!`find . -maxdepth 2 -type f \( -name 'README*' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' -o -name 'package.json' -o -name 'composer.json' -o -name 'go.mod' -o -name 'Cargo.toml' \) | sort | sed -n '1,80p'`

Create an implementation plan in the spirit of gstack's Think → Plan → Build → Review → Test → Ship flow.

Include:
- Problem framing and assumptions to verify
- Scope and non-goals
- Likely files and ownership boundaries
- Data/API/config/security impact
- Step-by-step implementation sequence
- Test and verification plan
- Review gates before commit/ship
- Rollback or recovery notes when relevant

Do not edit files. If the request is too ambiguous, ask only the smallest blocking questions.
