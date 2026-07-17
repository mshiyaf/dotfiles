# Scripts Dotfiles Package

> 📖 See [`docs/WORKFLOW.md`](../docs/WORKFLOW.md) for how `git-wt`, `crew`, and `gate` fit into
> the agentic workflow (parallel agents + ship gate playbooks).

GNU Stow package for personal CLI helpers. Everything lives under
`scripts/.local/bin/` and stows to `~/.local/bin/` (already on `$PATH`).

Install / update:

```bash
make stow-scripts     # or: make restow-scripts to pick up new files
```

## Contents

- `codex-status` - print ChatGPT/Codex usage and rate-limit status.
- `codex-resets` - show available reset credits for every saved OpenCode account.
- `ai-branch-name` - turn a free-text task into one git branch name (AI, with a slug fallback); used by `crew` and `wt`.
- `git-wt` - sibling git worktree manager (see below).
- `crew` - tmux/herdr multi-agent orchestrator built on `git-wt` (see below).
- `gate` - local AI ship gate: validate in a disposable worktree, then push + PR (see below).

## git-wt - parallel worktrees for agentic development

Runs coding agents (opencode, Claude, etc.) in parallel without them clobbering
each other, by giving each task/branch its own isolated checkout. Worktrees are
created as a **sibling** of the main repo, never nested inside it:

```text
~/dev/github.com/you/myrepo/                 <- main worktree
~/dev/github.com/you/myrepo.worktrees/foo    <- linked worktree for branch "foo"
~/dev/github.com/you/myrepo.worktrees/bar    <- linked worktree for branch "bar"
```

Keeping them outside the repo means they never get committed, indexed, or
scanned by tooling.

### Usage

Invoke as a git subcommand (`git wt ...`) or directly (`git-wt ...`):

```bash
git wt new <branch> [<start-point>]   # create a worktree (creates branch if new)
git wt list                           # list worktrees for this repo
git wt path <branch>                  # print the worktree path
git wt rm <branch> [-D] [--force]     # remove worktree (-D also deletes branch)
git wt prune                          # prune stale worktree metadata
git wt help
```

`new` auto-detects: if the branch already exists it is attached; otherwise a new
branch is created from `<start-point>` (default: `origin/HEAD`, else current HEAD).
The base `.worktrees` directory is auto-created and auto-removed when empty.

#### Post-create hook

If an executable `.worktrees-setup` exists at the **main repo root**, `git wt new`
runs it inside the freshly-created worktree - handy for copying `.env`, installing
deps, or warming a build cache. It runs with the new worktree as its working
directory, receives the branch name as `$1`, and the main repo root in
`$GIT_WT_MAIN`. Skip it for one run with `git wt new <branch> --no-setup`.

```bash
# example .worktrees-setup
#!/usr/bin/env bash
cp "$GIT_WT_MAIN/.env" . 2>/dev/null || true
[ -f package.json ] && npm ci
```

### `wt` shell function (cd support)

An external binary cannot change the parent shell's directory, so a `wt` zsh
function in `zsh/.config/zsh/.aliasrc` wraps `git-wt` to add `cd`. It is
**task-first**: describe the work and the branch is AI-named for you (via
`ai-branch-name`), so you don't have to invent a name:

```bash
wt "refactor the auth module"   # AI-name a branch, create the worktree + cd in
wt foo                          # cd into existing worktree/branch "foo" (no AI)
wt -b feat/foo                  # create/reuse an explicit branch, then cd
wt -b feat/foo main             # explicit branch from start-point "main", then cd
wt list                         # pass-through to `git wt list` (also: rm, path, prune, help)
```

Tab completion (`_wt`) offers subcommands, `-b`, and existing worktrees.

### Typical agentic flow

```bash
wt feature-x                 # spin up + enter an isolated checkout
opencode                     # let an agent work here
# ... in another terminal ...
wt feature-y                 # a second agent, fully isolated
# when done:
cd ~/dev/github.com/you/myrepo
git wt rm feature-x -D       # remove worktree + branch
```

## crew - tmux/herdr multi-agent orchestrator

`crew` runs several agents in parallel, each in its own `git wt` worktree and its own
detached tmux session or background herdr workspace. Our own lightweight take on firstmate -
no daemon, no external scripts. Run it from inside the target repo. The backend is
auto-detected per crewmate at spawn (herdr inside herdr, tmux inside tmux, else tmux if
installed; `CREW_BACKEND=tmux|herdr` forces one) and recorded in the state dir, so
`status`/`attach`/`stop` keep working from anywhere. On tmux, a crewmate with a task runs
**headless**; on herdr it launches the engine's **interactive TUI seeded with the task**
instead, so herdr's native agent detection tracks live status (working/blocked/idle) for
toasts and the sessionizer - pass `--headless` to keep the bounded non-interactive run.
A crewmate with a task runs **bounded**: it may
edit, run tests, and commit on its branch, then stops - it never pushes. Each engine is
constrained to that effect - auto-approve everything except an explicit deny-list, never a full
yolo mode: `opencode` via `--agent crewmate --auto` (auto-approves, but the agent still denies
`git push`/`sudo`/hard-reset; `--auto` is required since headless `run` has no TTY to approve),
`claude` via `--permission-mode acceptEdits` + a `git push`/`sudo`/hard-reset deny-list, `codex`
via the `workspace-write` sandbox (network off, so push is blocked), and Kimi Code via print
mode's auto permission policy plus explicit local-only, non-destructive task guardrails.

`crew` is **task-first**: give it the task and the branch is AI-named for you
(via `ai-branch-name`, printed as `-> branch: ...`). Pass `-b/--branch <name>`
only when you want to reuse or force a specific branch.

```bash
crew new "add dark mode"             # standard profile: Terra / Sonnet / Terra
crew new --profile fast "update README examples"
crew new --profile deep --claude "fix transaction race" --attach
crew new --profile fast --kimi "update shell completion docs"
crew new -b feat/dark "add toggle"   # force the branch name
crew new -b spike-y                  # no task -> interactive opencode in the worktree
crew status                          # branch | engine | profile | model | running/done(rc) | commits-ahead
crew logs feat/dark -f               # follow a crewmate's captured output
crew watch                           # bell + notify-send when a crewmate finishes or blocks
crew ls                              # list active crew sessions / workspaces
crew attach feat/dark                # attach / switch-client to a crewmate
crew stop feat/dark -D               # kill session (-D also removes worktree + branch)
```

Profiles explicitly select the model for every engine rather than inheriting machine defaults:

| Profile | Use for | OpenCode | Claude | Codex | Kimi Code |
| --- | --- | --- | --- | --- | --- |
| `fast` | Mechanical docs, formatting, boilerplate | Luna Fast | Haiku | Luna Fast | K2.7 Code |
| `standard` (default) | Normal implementation and tests | Terra | Sonnet | Terra | K2.7 Code |
| `deep` | Architecture-sensitive work, concurrency, security, difficult debugging | Sol | Opus | Sol | K3 |

Kimi is opt-in with `--kimi`; OpenCode remains the default engine.
Kimi tasks run headlessly on both tmux and Herdr because Kimi Code does not provide a documented
way to seed a prompt into its interactive TUI.
Interactive Kimi sessions are still available with `crew new -b <branch> --kimi`.

crew is **scoped per repository**: sessions/workspaces are named `crew_<repo-key>_<branch>` and
state lives in `~/.local/state/crew/<repo-key>/<branch>/` (`branch`, `worktree`, `session`, `task`,
`engine`, `profile`, `model`, `log`, `status`, `backend`, and on herdr `workspace_id`/`pane_id`).
The repo key is derived from the shared `--git-common-dir`, so it is stable from the
main repo or any of its worktrees. `crew ls`/`status`/`watch` show only the current repo's
crewmates (two repos can each run a `feat-x` without colliding); pass `--all` for the cross-repo
view. This is what `crew status`, `crew logs`, and `crew watch` read and `crew stop` clears. Run `crew watch`
in its own pane for zero-token, event-driven alerts (bell + `notify-send`) the moment a crewmate
is ready or blocked - the push layer a chat agent cannot provide on its own. Tab completion (`_crew`)
offers subcommands, `new` flags, and live sessions for `attach`/`stop`. Prefer the captain?
`/crew "build A, B, C"` in OpenCode dispatches crewmates and reports on request (it does not poll
in a loop). `claude --tmux` / `claude --bg` are native alternatives if you prefer Claude Code's
own worktree/background orchestration.

## gate - local AI ship gate

`gate` validates a branch's committed work in a **disposable worktree**, then pushes and
opens a PR only if the gate passes. Our own take on no-mistakes - no external binary,
built on `git-wt` + `opencode`/`claude`/`codex`/`kimi` + `gh`.

```bash
gate init                          # optional: seed OpenCode .gate.sh overrides
gate init --engine kimi            # optional Kimi variant; does not change the default
gate status        # show the resolved config
gate run [branch]  # review → test → docs → lint (+auto-fix) → push → PR → CI monitor
```

Pipeline: a **structured review** (JSON findings classified
`auto_fix` vs `ask_user` - `auto_fix` are applied automatically; `ask_user` are a human-approval
gate: prompted interactively, or blocked when headless), then `test` → `docs` → `lint` stages.
If `GATE_TEST` or `GATE_LINT` is set, that deterministic command runs with a bounded auto-fix loop.
If either is empty, the build agent detects and runs relevant checks for the repo.
Docs run only when `GATE_DOCS` is set; empty docs is skipped by default.
On pass it fast-forwards
your local branch, pushes, and opens a PR; with `GATE_WATCH_CI=1` it then watches the PR's checks
and auto-fixes CI failures from the logs. On an unfixable failure (or a blocked review) it
**escalates** - nothing is pushed and the disposable worktree is kept. A review evidence trail is
written under `GATE_EVIDENCE_DIR` (gitignored). Optional overrides live in `.gate.sh` (plain sourced bash):

```bash
GATE_TEST=""                                                     # empty = agent auto-detect
GATE_DOCS=""                                                     # empty = skip
GATE_LINT=""                                                     # empty = agent auto-detect
# GATE_TEST="pnpm test"
# GATE_LINT="pnpm lint"
# GATE_DOCS="pnpm docs:check"
GATE_REVIEW_CMD='gate_review_opencode'                            # "" to skip
GATE_REVIEW_APPROVE=1        # 1 = gate ask_user findings; 0 = informational
GATE_FIX_CMD='opencode run "$GATE_PROMPT" --agent build --auto'
GATE_MAX_ROUNDS=3
GATE_EVIDENCE_DIR=".gate/evidence"
GATE_WATCH_CI=0             # 1 = watch CI after the PR and auto-fix failures
GATE_PUSH_REMOTE="origin"
```

The LLM only classifies findings; you approve the judgment calls (or a headless run blocks on
them), so an LLM verdict is never trusted as an exit code. Commit your work before running - the
gate validates commits, and it refuses to run on the default branch. Requires `jq` and `gh`.
`gate` inherits the shell environment you run it from. Put worktree-specific bootstrap in
`.worktrees-setup`, for example copying `.env` from `$GIT_WT_MAIN` and installing dependencies.
