---
name: git-commit
description: Use when creating git commits, drafting commit messages, branch names, or concise git summaries from staged or unstaged changes.
---
## Procedure
- Inspect staged changes first.
- For `/commit` or an explicit commit request, create a commit from staged changes after choosing the message.
- If no changes are staged, do not stage automatically unless the user explicitly asked for that; say what needs staging.
- Follow Conventional Commits by default: `<type>(optional-scope): <description>`.
- Use common types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Prefer one concise subject under 72 characters when practical.
- Use lowercase type/scope and imperative, present-tense description.
- Mention why the change exists, not every file touched.
- Add a body only when it explains non-obvious motivation, tradeoffs, migration, or risk.
- Mark breaking changes with `!` in the subject and `BREAKING CHANGE:` in the body.
- Warn if secrets, generated artifacts, lockfiles, or unrelated changes appear.
- After committing, verify with `git status --short`.
- Do not amend commits unless the user explicitly requested amend.

## Examples
- `fix(auth): reject expired sessions`
- `feat(api): add cursor pagination`
- `docs(readme): clarify local setup`
- `refactor(db): isolate migration helpers`
- `feat!: remove legacy webhook payload`
