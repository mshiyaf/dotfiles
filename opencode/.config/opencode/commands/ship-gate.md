---
description: Run the ship gate - validate in a disposable worktree, then push + open a PR.
agent: build
---
Run our own ship gate on the current branch. It validates committed work in a
disposable worktree (structured review → test → docs → lint, with a bounded auto-fix
loop) and only pushes + opens a PR if the gate passes. No external tools.

Preflight:
!`git rev-parse --abbrev-ref HEAD`
!`git status --short`
!`test -f .gate.sh && echo ".gate.sh present" || echo "no .gate.sh - run /init-gate first"`

Steps:
1. If there is no `.gate.sh`, tell the user to run `/init-gate` and stop.
2. If the working tree is dirty, tell the user to commit or stash first (the gate validates commits).
3. Run the gate and surface its output:
   !`gate run 2>&1 || true`
4. Summarize: did it pass and push? If it escalated, list what failed and the kept
   worktree path. Do not push or open a PR yourself - `gate` handles that on pass.
5. Note: this runs headless, so the review's `ask_user` findings cannot be approved here
   and will **block** the ship. If the gate blocks on review, tell the user to run
   `gate run` in a terminal to approve/fix those findings (or set `GATE_REVIEW_APPROVE=0`
   for informational-only review).
