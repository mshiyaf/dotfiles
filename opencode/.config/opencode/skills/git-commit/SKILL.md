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
- For actual commits, include a short body after the subject by default. The body should explain the change and why it exists in 1-3 concise bullet points or sentences.
- Omit the body only for truly trivial commits, such as typo-only docs edits or one-line formatting changes.
- If verification was run or intentionally skipped, include it in the body when useful for future readers.
- Mark breaking changes with `!` in the subject and `BREAKING CHANGE:` in the body.
- Warn if secrets, generated artifacts, lockfiles, or unrelated changes appear.
- After committing, verify with `git status --short`.
- Do not amend commits unless the user explicitly requested amend.
- Use multi-line commit commands so the body is preserved, for example:
  ```bash
  git commit -m "type(scope): concise subject" -m "Explain what changed and why."
  ```
- Do not create subject-only commits for `/commit` unless the staged diff is genuinely trivial.

## Examples
- `fix(auth): reject expired sessions`
- `feat(api): add cursor pagination`
- `docs(readme): clarify local setup`
- `refactor(db): isolate migration helpers`
- `feat!: remove legacy webhook payload`

## Descriptive Commit Example
```text
fix(auth): reject expired sessions

- Validate session expiry before loading account state.
- Keeps expired cookies from being treated as active sessions.

Verification: vendor/bin/phpunit tests/Feature/AuthTest.php
```
