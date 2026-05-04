---
description: Create a git commit from staged changes.
agent: pr-writer
---
Use the git-commit skill.

Context:
!`git status --short`
!`git diff --stat`
!`git diff --cached --stat`
!`git diff --cached`
!`git log --oneline -10`

Create a git commit from the currently staged changes.

Rules:
- If nothing is staged, do not stage files automatically. Say what needs staging.
- Do not commit secrets, credentials, `.env` files, or unrelated generated artifacts.
- Use a concise Conventional Commit message.
- Run `git commit` with the message, then run `git status --short` to verify.
- If commit hooks fail, report the failure and what needs fixing. Do not amend.
