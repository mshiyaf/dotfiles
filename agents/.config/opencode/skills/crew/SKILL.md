---
name: crew
description: Use when orchestrating several agents in parallel - split a request into independent features, dispatch one crewmate per feature with the `crew` CLI, then stop and report status on request (not continuously) so ready branches can be reviewed and shipped.
---
## What it is
`crew` runs multiple agents in parallel, each in its own `git wt` worktree and detached tmux
session or background herdr workspace (backend auto-detected; on herdr a task runs the engine's
interactive TUI with live status, `--headless` for the bounded non-interactive run).
You are the **captain**: you plan, dispatch, and monitor - you do not write code
yourself. Each crewmate implements one feature and commits on its own branch. Crewmates never
push; the user reviews and ships each ready branch.

## When to use
The user asks to build 2-3 (or more) independent features/fixes at once, or to fan a batch of
similar changes across a codebase. If the work is a single change, do it directly instead - crew
is overhead you only want for genuine parallelism.

## Native subagents versus crew
Use native subagents, including Kimi Code's `AgentSwarm` and Amp's `Task` tool, for parallel
read-only exploration, review, research, or tightly coordinated subtasks that contribute to one
main-agent result.
Use `crew` when each task should independently edit, test, and commit a shippable branch.
Native subagents share the parent workspace and are not a substitute for crew's Git worktree
isolation. Do not dispatch concurrent editing subagents that may touch the same files.

## The protocol
1. **Split** the request into independent features. Each must be shippable on its own and must
   not fight another crewmate over the same files (crewmates do not coordinate shared edits).
   If two "features" touch the same core file, merge them into one task or sequence them.
2. **Name + brief** each feature: a short branch name (`feat-dark-mode`) and a crisp,
   self-contained task string. The crewmate has no other context, so the task must state the
   goal, the acceptance criteria, and any constraint. It does not need commit/push instructions -
   `crew` appends those.
3. **Dispatch** one crewmate per feature:
   ```bash
   crew new "<self-contained task>"
   # Or force a branch name:
   crew new -b <branch> "<self-contained task>"
   ```
   OpenCode is the default engine. Add `--claude`, `--codex`, `--kimi`, or `--amp` to select another
   engine. Kimi tasks use regular K2.7 for `fast` and `standard`, K3 for `deep`, and run
   headlessly because Kimi has no documented seeded-prompt interactive launch mode. Amp uses
   `low` for `fast` and `medium` for both `standard` and `deep`; Crew never selects Amp's costly
   `high` or `ultra` modes.
4. **Report and stop.** After dispatching, tell the user what you launched and how to check in
   (`crew status`, `crew logs <branch>`, and `crew watch` in a separate pane for push alerts when a
   crewmate is ready or blocked), then **end your turn and hand control back**. There is no live
   watcher inside you: do not sit in a `crew status` loop narrating progress - that just spams the
   user and burns tokens. Reporting is **on request**, not continuous.
5. **Status on request.** When the user asks how it's going, run `crew status` once (and
   `crew logs <branch>` if a line needs context), summarize, and stop:
   ```bash
   crew status            # branch | running/done(rc) | commits-ahead | last log line
   crew logs <branch>     # full captured output (-f to follow)
   ```
   - **Blocked**: a crewmate that hits an ambiguous requirement prints `BLOCKED: <reason>` and
     stops. Surface that reason and ask the user how to proceed; do not guess for them.
   - **Ready**: a crewmate that shows `done` with commits-ahead > 0 is **ready for review**. List
     the ready branches with a one-line summary each.

## Rules
- Never push or merge. Hand ready branches to the user to review (`/review-diff`) and ship
  (`/ship-gate`). A crewmate `done:0` means it committed, not that the work is correct.
- Choose independent features. If a plan needs shared-file coordination, say so and sequence it
  rather than dispatching colliding crewmates.
- One crewmate per branch. Re-running `crew new` on an existing branch reuses its session.
- Tear down finished crewmates with `crew stop <branch>` (add `-D` to also drop the worktree +
  branch once its work is merged).
