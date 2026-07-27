---
name: handoff
description: Creates a compact, evidence-based handoff for another agent or session. Use when transferring work, changing tools, resetting context, pausing a task, or resuming later.
---

# Handoff

Preserve the minimum context another agent or session needs to continue safely.

## Procedure

1. Identify the receiving session's objective and expected next action.
2. Inspect current repository state when relevant: branch, worktree, status, commits, diff summary, and verification output.
3. Reference canonical plans, tickets, decisions, research, and files instead of duplicating their contents.
4. Redact secrets, credentials, tokens, personal data, and unrelated conversation details.
5. Create the handoff outside the repository in `$TMPDIR` or the operating system's temporary directory unless the user explicitly requests a project artifact.
6. Return the handoff path and a concise summary.

If the harness cannot write outside the workspace, return the complete handoff in the response and state that it was not persisted.
Do not create a repository file merely as a sandbox workaround.

Do not modify project files, commit, publish, or launch another agent unless explicitly requested.

## Required format

```markdown
# Objective

# Current status

# Decisions made

# Canonical artifacts

# Changes made
- Branch/worktree:
- Commits or uncommitted state:
- Materially affected files:

# Verification
- Exact commands and outcomes:
- Skipped checks and reasons:

# Open questions

# Risks and constraints

# Next recommended action

# Suggested skills or agents
```

State uncertainty plainly.
Never claim a check passed unless its result was observed.
