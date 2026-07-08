---
name: investigate
description: Use when investigating bugs, failures, flaky behavior, or suspicious code paths before proposing fixes.
---

# Investigate

Use this skill for systematic read-only investigation before fixing.

Gather context first when available:

- Run `git status --short`.
- Run `git branch --show-current`.
- Run `git log --oneline -10`.
- Read the reported error, failing output, or relevant diff before searching broadly.

Use `systematic-debugging`, `debugging`, `grounding`, `code-review`, and `test-writer` skills when relevant.

Investigate before fixing:

- Reproduce or identify the failing path if possible.
- Gather evidence from code, logs, tests, or diffs.
- Trace the smallest relevant data/control flow.
- State the root cause and confidence level.
- Propose the smallest safe fix and verification command.
- Stop and reassess after three failed fix hypotheses.

Do not edit files unless the user explicitly asks you to fix it after the investigation.
