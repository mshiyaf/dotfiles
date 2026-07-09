---
name: ship-gate
description: Use when shipping a branch through the local AI ship gate - validate in a disposable worktree, auto-fix, then push and open a PR. Covers the `gate` CLI, optional .gate.sh overrides, and .worktrees-setup bootstrap.
---
## What it is
`gate` is a local ship gate (our own, no external binary). It validates a branch's
committed work in a **disposable worktree** and only pushes + opens a PR once the gate
passes. Built on `git-wt` + your coding agent + `gh`.

## Pipeline
1. Copy the current branch HEAD into a disposable worktree (your working tree is untouched).
2. **review** - structured: the reviewer (via the `gate-review` skill) emits JSON findings classified
   `auto_fix` vs `ask_user`. `auto_fix` findings are applied automatically; `ask_user` findings are
   gated on **human approval** - prompted interactively (approve / fix / block), or **blocked** when
   headless (`GATE_REVIEW_APPROVE=0` makes them informational instead). Evidence is written under
   `GATE_EVIDENCE_DIR`. The LLM only classifies; the human decides.
3. **test** - explicit command if `GATE_TEST` is set; otherwise the build agent detects and runs relevant tests.
4. **docs** - explicit command if `GATE_DOCS` is set; otherwise skipped by default.
5. **lint** - explicit command if `GATE_LINT` is set; otherwise the build agent detects and runs relevant lint/format/static checks.
6. On pass: fast-forward the local branch, push validated commits, `gh pr create`.
7. **CI monitor** (opt-in, `GATE_WATCH_CI=1`): watch the PR's checks; on failure, auto-fix from the
   logs, push, and re-watch, bounded by `GATE_MAX_ROUNDS`.
8. On failure after the round cap (or a blocked review): **escalate** - nothing is pushed, the
   disposable worktree is kept for inspection.

## Config - optional `.gate.sh` overrides (sourced bash, not YAML)
`gate run` works without `.gate.sh`.
Seed optional deterministic overrides with `gate init`.
Fields: `GATE_TEST`, `GATE_DOCS`, `GATE_LINT`, `GATE_REVIEW_CMD` (structured JSON review; empty = skip),
`GATE_REVIEW_APPROVE` (1 = gate `ask_user` findings, 0 = informational), `GATE_FIX_CMD` (`%s` = fix prompt),
`GATE_MAX_ROUNDS`, `GATE_EVIDENCE_DIR`, `GATE_WATCH_CI`, `GATE_PUSH_REMOTE`, `GATE_PR_ARGS`.
Leave `GATE_TEST` and `GATE_LINT` empty for agent auto-detection.
Leave `GATE_DOCS` empty to skip docs by default.

## Worktree Bootstrap
`gate` inherits the shell environment it is run from.
Put worktree-specific setup in an executable `.worktrees-setup` at the main repo root.
`git wt new` runs it inside new worktrees with `$GIT_WT_MAIN` pointing at the main repo.

```bash
#!/usr/bin/env bash
cp "$GIT_WT_MAIN/.env" . 2>/dev/null || true
pnpm install --frozen-lockfile
```

## Usage
```bash
gate init          # optional: write .gate.sh deterministic overrides
gate status        # show resolved config
gate run [branch]  # validate → push → PR (default: current branch)
```

## Rules
- Commit your work first; the gate validates commits, not the dirty tree.
- Never bypass the gate to push a failing branch. If it escalates, fix the reported
  failures (or the kept worktree) and re-run. No yolo.
- `gate` refuses to run on the default branch.
