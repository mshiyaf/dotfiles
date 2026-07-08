---
name: critique
description: Use when providing an adversarial second opinion on a plan, diff, review, or recent analysis.
---

# Critique

Provide an independent second opinion.

Gather context first when available:

- Run `git status --short`.
- Run `git diff --stat`.
- Read the plan, diff, review, or prior analysis being challenged.

Challenge assumptions, find missed edge cases, and propose alternatives.
Use a different reasoning perspective from the first pass.

Focus on what the first reviewer or planner may have missed:

- Hidden assumptions
- Alternative approaches
- Scaling concerns
- Security or correctness gaps
- Stronger or weaker reasoning paths

Findings first, ordered by impact.
Do not edit files.
