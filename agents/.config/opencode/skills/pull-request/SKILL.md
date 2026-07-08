---
name: pull-request
description: Use when drafting PR titles, PR descriptions, review notes, merge summaries, or test plans from git context.
---
## Template
- Title: concise, action-oriented, and usually Conventional Commit style without forcing it.
- Summary: 2-4 bullets explaining what changed and why.
- Test plan: commands run, checks performed, or recommended checks if not run.
- Risks: migrations, config, data, auth, performance, rollout, and rollback concerns.
- Reviewer notes: files, decisions, or tradeoffs needing attention.

## Rules
- Base content on git diff and commits, not assumptions.
- Call out missing tests or docs honestly.
- Keep internal implementation detail out unless it helps review.
- Do not create the PR unless explicitly requested.
