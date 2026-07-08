---
name: ship-gate
description: Use when shipping a branch through the local AI ship gate - validate in a disposable worktree, auto-fix, then push and open a PR. Covers the `gate` CLI and .gate.sh config.
---
## What it is
`gate` is a local ship gate (our own, no external binary). It validates a branch's
committed work in a **disposable worktree** and only pushes + opens a PR once the gate
passes. Built on `git-wt` + your coding agent + `gh`.

## Pipeline
1. Copy the current branch HEAD into a disposable worktree (your working tree is untouched).
2. **review** - advisory only: surfaces findings, never blocks (LLM verdicts are unreliable
   as exit codes, so review informs while tests/lint enforce).
3. **test** - enforced, bounded auto-fix loop (`GATE_MAX_ROUNDS`).
4. **lint** - enforced, bounded auto-fix loop.
5. On pass: fast-forward the local branch, push validated commits, `gh pr create`.
6. On failure after the round cap: **escalate** - nothing is pushed, the disposable
   worktree is kept for inspection.

## Config - `.gate.sh` (sourced bash, not YAML)
Seed it with `gate init`. Fields: `GATE_TEST`, `GATE_LINT`, `GATE_REVIEW_CMD` (empty = skip),
`GATE_FIX_CMD` (`%s` = fix prompt), `GATE_MAX_ROUNDS`, `GATE_PUSH_REMOTE`, `GATE_PR_ARGS`.
Set any command to `""` to skip that stage.

## Usage
```bash
gate init          # once per repo
gate status        # show resolved config
gate run [branch]  # validate → push → PR (default: current branch)
```

## Rules
- Commit your work first; the gate validates commits, not the dirty tree.
- Never bypass the gate to push a failing branch. If it escalates, fix the reported
  failures (or the kept worktree) and re-run. No yolo.
- `gate` refuses to run on the default branch.
