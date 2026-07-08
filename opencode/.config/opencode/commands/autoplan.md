---
description: Produce an end-to-end implementation plan without editing files.
agent: architect
---
Use api-design, code-review, test-writer, security-review, database-review, and refactor-planner skills when relevant.
Use the autoplan skill.

Goal:
$ARGUMENTS

Context:
!`git status --short`
!`git branch --show-current`
!`git log --oneline -10`
!`find . -maxdepth 2 -type f \( -name 'README*' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' -o -name 'package.json' -o -name 'composer.json' -o -name 'go.mod' -o -name 'Cargo.toml' \) | sort | sed -n '1,80p'`

Do not edit files.
