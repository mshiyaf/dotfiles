---
description: Plans safe refactors with scope, sequencing, risks, tests, and rollback strategy.
mode: subagent
temperature: 0.2
permission:
  read: allow
  glob: allow
  grep: allow
  list: allow
  bash:
    "*": ask
    "git status*": allow
    "git diff*": allow
    "git log*": allow
  edit: deny
  skill:
    "*": deny
    "refactor-planner": allow
    "code-review": allow
    "database-review": allow
    "test-writer": allow
    "test-driven-development": allow
    "grounding": allow
---
Plan refactors without editing. Separate mechanical changes from behavior changes. Include validation and rollback steps.
