# Global agent instructions

Shared by Claude Code, Codex, and OpenCode.
Keep this file short; it loads into every agent's context.
Project-specific rules live in each repo's own `AGENTS.md`.

## Working style
- Plan before non-trivial work; build directly for small, well-understood changes.
- When you have enough to act, act. Don't re-derive facts already in context.
- Lead with the shortest useful answer; expand only when asked.
- On technical decisions, don't give much weight to development cost.
  Prefer quality, simplicity, robustness, scalability, and long-term maintainability.

## Safety
- Confirm before hard-to-reverse or outward-facing actions (push, deploy, delete, send).
- Never auto-push, auto-merge, or enable yolo / skip-permission modes on your own.
- Before deleting or overwriting, look at the target; if it contradicts expectations, stop and surface it.

## Commits
- Conventional-commit style subjects (`feat:`, `fix:`, `chore:` ...).
- Commit or push only when asked. Branch first if on the default branch.
- Never auto-add the agent name as a co-author or `Co-Authored-By` trailer.

## Quality bar
- No half-done work. If tests fail or a step is skipped, say so plainly with the output.
- Fix bugs by first reproducing them end-to-end, as a real user would.
  That is how you find the real problem so the fix actually solves it.
- Boy-scout rule: if you notice lint errors, test failures, or flaky tests, fix them even if unrelated to your task.
- UI/UX: match existing tokens, spacing, and states (loading / empty / error).
  Be obsessed with pixel perfection; if something clearly looks off, fix it even if it is not what you set out to do.

## Writing
- Never use em dashes. Use a plain hyphen "-" instead.
- In long Markdown files, put each full sentence on its own physical line (semantic line breaks).
  Preserve normal Markdown structure; just avoid wrapping multiple sentences onto one line.
- Don't hand-edit auto-generated files: lockfiles, `CHANGELOG.md`, or anything marked generated.
  Regenerate them with their tool.

## Token efficiency
- Don't re-read files already shown in context.
- Reviews: findings first, severity-tagged, one line of context each. Don't summarize a diff the user can read.
- Prefer targeted `grep` / read over broad `find` / `cat`.

## More context
- For decisions that would benefit from the user's viewpoints, read `~/OPINIONS.md`.
- When writing or posting as the user, read `~/VOICE.md` for their voice.
