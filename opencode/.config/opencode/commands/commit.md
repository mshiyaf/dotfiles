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
- Use a concise Conventional Commit subject plus a short descriptive body by default.
- The body should explain what changed and why in 1-3 bullets or sentences. Include verification when useful.
- Omit the body only for truly trivial changes.
- Run `git commit` with separate subject/body arguments, for example `git commit -m "type(scope): subject" -m "body"`, then run `git status --short` to verify.
- If commit hooks fail, report the failure and what needs fixing. Do not amend.
