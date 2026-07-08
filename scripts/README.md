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
- `git-wt` - sibling git worktree manager (see below).
- `crew` - tmux multi-agent orchestrator built on `git-wt` (see below).
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
function in `zsh/.config/zsh/.aliasrc` wraps `git-wt` to add `cd`:

```bash
wt foo            # cd into worktree "foo" (creates it first if missing)
wt foo main       # create "foo" from main, then cd into it
wt list           # pass-through to `git wt list` (also: rm, path, prune, help)
```

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

## crew - tmux multi-agent orchestrator

`crew` runs several agents in parallel, each in its own `git wt` worktree and its own
detached tmux session. Our own lightweight take on firstmate - no daemon, no external
scripts. Run it from inside the target repo. A crewmate with a task runs **bounded**: it may
edit, run tests, and commit on its branch, then stops - it never pushes. Each engine is
constrained to that effect - auto-approve everything except an explicit deny-list, never a full
yolo mode: `opencode` via `--agent crewmate --auto` (auto-approves, but the agent still denies
`git push`/`sudo`/hard-reset; `--auto` is required since headless `run` has no TTY to approve),
`claude` via `--permission-mode acceptEdits` + a `git push`/`sudo`/hard-reset deny-list, `codex`
via the `workspace-write` sandbox (network off, so push is blocked).

```bash
crew new feature-x "add dark mode"   # worktree + tmux session: opencode run "..." --agent crewmate
crew new spike-y                     # no task -> interactive opencode in the worktree
crew new fix-z --claude "fix flaky test" --attach   # use claude, jump straight in
crew status                          # branch | running/done(rc) | commits-ahead | last log line
crew logs feature-x -f               # follow a crewmate's captured output
crew watch                           # bell + notify-send when a crewmate finishes or blocks
crew ls                              # list active crew tmux sessions
crew attach feature-x                # attach / switch-client to a crewmate
crew stop feature-x -D               # kill session (-D also removes worktree + branch)
```

Sessions are named `crew_<branch>`. Per-crewmate state lives in
`~/.local/state/crew/<session>/` (`branch`, `worktree`, `task`, `log`, `status`) - this is
what `crew status`, `crew logs`, and `crew watch` read and `crew stop` clears. Run `crew watch`
in its own pane for zero-token, event-driven alerts (bell + `notify-send`) the moment a crewmate
is ready or blocked - the push layer a chat agent cannot provide on its own. Prefer the captain?
`/crew "build A, B, C"` in OpenCode dispatches crewmates and reports on request (it does not poll
in a loop). `claude --tmux` / `claude --bg` are native alternatives if you prefer Claude Code's
own worktree/background orchestration.

## gate - local AI ship gate

`gate` validates a branch's committed work in a **disposable worktree**, then pushes and
opens a PR only if the gate passes. Our own take on no-mistakes - no external binary,
built on `git-wt` + `opencode`/`claude` + `gh`.

```bash
gate init          # seed a .gate.sh config in the repo (once)
gate status        # show the resolved config
gate run [branch]  # validate (review → test → lint, +auto-fix) → push → gh pr create
```

Pipeline: an advisory **review** (surfaces findings, never blocks), then **enforced**
`test` and `lint` stages, each with a bounded auto-fix loop (`GATE_MAX_ROUNDS`). On pass
it fast-forwards your local branch, pushes the validated commits, and opens a PR. On an
unfixable failure it **escalates** - nothing is pushed and the disposable worktree is kept
for inspection. Config lives in `.gate.sh` (plain sourced bash, not YAML):

```bash
GATE_TEST="npm test"
GATE_LINT="npm run lint"
GATE_REVIEW_CMD='opencode run "/review-diff" --agent reviewer'   # "" to skip
GATE_MAX_ROUNDS=3
GATE_PUSH_REMOTE="origin"
```

Commit your work before running - the gate validates commits, and it refuses to run on
the default branch.
