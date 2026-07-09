---
name: gate-review
description: Use when the ship gate needs a structured code review - inspect the branch diff and output findings as a single JSON object classified auto_fix vs ask_user. Output only JSON, no prose.
---
## What it is
The `gate` CLI calls this to get machine-readable review findings. You review the current branch's
committed changes against its base branch and return findings as **one JSON object**. The gate
auto-applies `auto_fix` findings and gates `ask_user` findings on human approval, so classification
matters.

## How
1. Get the diff to review (committed work on this branch, not the base):
   ```bash
   base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
   git diff "$(git merge-base "$base" HEAD)"...HEAD
   ```
2. Review it for correctness, regressions, security, and clarity.
3. Emit exactly this shape (and nothing else):
   ```json
   {"findings":[
     {"id":"F1","severity":"high|medium|low","class":"auto_fix|ask_user",
      "file":"path/to/file","line":0,"summary":"one-line problem","suggested_fix":"concrete instruction"}
   ]}
   ```
   No findings is valid: `{"findings":[]}`.

## Classification (the important part)
- **`auto_fix`** = safe, mechanical, unambiguous. A machine could apply `suggested_fix` without
  judgment: typos, unused imports/variables, dead code, obvious missing null/undefined guards,
  clearly-wrong off-by-one, formatting a linter would miss, a wrong constant with one right value.
- **`ask_user`** = needs human judgment: logic/correctness questions, security or performance
  trade-offs, architecture, public API or behavior changes, anything where the fix is a *decision*
  rather than a mechanic.

## Rules
- Output **only** the JSON object - no commentary, no markdown fences, nothing before or after.
- Be conservative with `auto_fix`: when in doubt, classify as `ask_user`. A wrong auto_fix ships
  unreviewed; a wrong ask_user only costs a prompt.
- `suggested_fix` must be specific enough to apply directly (name the change, not "consider ...").
- Give each finding a unique `id` (`F1`, `F2`, ...).
