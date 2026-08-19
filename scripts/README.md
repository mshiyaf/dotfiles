# Scripts Dotfiles Package

> 📖 See [`docs/WORKFLOW.md`](../docs/WORKFLOW.md) for how `git-wt`, `crew`, and `gate` fit into
> the agentic workflow (parallel agents + ship gate playbooks).

GNU Stow package for personal CLI helpers. Commands live under `scripts/.local/bin/` and stow to
`~/.local/bin/` (already on `$PATH`); support data lives under `scripts/.local/share/`.

Install / update:

```bash
make stow-scripts     # or: make restow-scripts to pick up new files
```

## Contents

- `ai-usage` (`aiu` alias) - show usage limits and reset times for all installed coding agents, ranked by what to use first, with a "Use first" suggestion.
- `ai-account` - save and switch Claude Code and native Codex CLI logins without changing their shared settings or session history.
- `codex-status` - focused status for the active native Codex account, with JSON and watch modes.
- `codex-resets` - show earned rate-limit reset credits, which are separate from normal quota usage.
- `ai-branch-name` - turn a free-text task into one git branch name (AI, with a slug fallback); used by `crew` and `wt`.
- `git-wt` - sibling git worktree manager (see below).
- `crew` - tmux/herdr multi-agent orchestrator built on `git-wt` (see below).
- `gate` - local AI ship gate: validate in a disposable worktree, then push + PR (see below).
- `amp-global-sync` - sync the orb-safe skill/plugin subset into local Amp Personal repository checkouts without committing or pushing.
- `check-app-updates` / `update-apps` - version check + interactive updater for apps installed
  outside pacman (see below).

## ai-account - Claude and Codex login profiles

Import the account that is currently logged in, then log in to a second account:

```bash
ai-account save claude personal
ai-account login claude work

ai-account save codex personal
ai-account login codex work
```

Switch by name, or omit the name to choose with `fzf`:

```bash
claude-account personal
claude-account                 # interactive picker
codex-account work
ai-account list
```

`aiu` shows every saved Claude and native Codex profile by name alongside the existing OpenCode profiles.
Claude's custom status line also shows the active profile as `acct:<name>`.
Codex does not support a custom status-line account field, so use `ai-account current codex`; `codex-status` also labels its active-account output.

The profile files live under `~/.local/share/ai-accounts/` with mode `0600`.
Only `~/.claude/.credentials.json` or `~/.codex/auth.json` is swapped, so the normal settings and sessions remain shared.
The active credential is saved before every switch to retain refreshed tokens.
Switch only after existing sessions for that provider have exited, then start a new session.

## amp-global-sync - prepare Amp Personal Skills and Plugins

Keep the shared dotfiles skill directory as the canonical source while making portable behavior available in Amp orbs:

```bash
make amp-global-sync
```

The command clones or updates the Amp Personal Skills and Plugins repositories under `~/.cache/amp/repositories/`, validates the source configuration, and copies the managed subset.
It excludes the local-runner-only `crew` and `ship-gate` skills, excludes `.system`, copies only `proposal-writing/SKILL.md` because global Amp Skills do not serve its binary DOCX assets, and installs only the custom `workflow-guardrails.ts` plugin.
It refuses to overwrite dirty checkouts or unmanaged entries with the same name, then prints the pending Git status and diff summary.
It never commits or pushes.

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
background Herdr workspace or detached tmux session. Herdr is the primary local backend and tmux
is the fallback. This is our own lightweight take on firstmate -
no daemon, no external scripts. Run it from inside the target repo. The backend is
auto-detected per crewmate at spawn (herdr inside herdr, tmux inside tmux, else tmux if
installed; `CREW_BACKEND=tmux|herdr` forces one) and recorded in the state dir, so
`status`/`attach`/`stop` keep working from anywhere.
Every tasked crewmate runs headlessly on both Herdr and tmux, then exits when its bounded work is complete.
A branch-only launch without a task remains interactive.
A crewmate with a task runs **bounded**: it may
edit, run tests, and commit on its branch, then stops - it never pushes. Each engine is
constrained to that effect - auto-approve everything except an explicit deny-list, never a full
yolo mode: `opencode` via `--agent build --auto` plus a Crew-only global policy inherited by
delegated subagents (auto-approves edits and routine commands, but still denies `git push`/`sudo`/
hard-reset/`git clean`/dangerous `rm -rf`; `--auto` is required since headless `run` has no TTY),
`claude` via `--permission-mode acceptEdits` + a `git push`/`sudo`/hard-reset deny-list, `codex`
via the `workspace-write` sandbox (network off, so push is blocked), and Kimi Code via print
mode's auto permission policy plus explicit local-only, non-destructive task guardrails. Amp uses
minimal execute-mode settings plus the required `workflow-guardrails` plugin, which parses direct
shell commands and rejects risky operations without false-blocking quoted text.
Headless Claude runs use its realtime event stream to log concise agent updates and tool activity
while omitting thinking and verbose tool results, so `crew status` and `crew logs -f` remain useful
before the task finishes.
Set `CREW_AMP_SETTINGS` only when supplying equivalent execute-mode settings.
The guard plugin must be installed at Amp's system plugin path via `make restow-amp`.

`crew` is **task-first**: give it the task and the branch is AI-named for you
(via `ai-branch-name`, printed as `-> branch: ...`). Pass `-b/--branch <name>`
only when you want to reuse or force a specific branch.

```bash
crew new "add dark mode"             # standard profile: Terra / Sonnet / Terra
crew new --profile fast "update README examples"
crew new --profile deep --claude "fix transaction race" --attach
crew new --profile fast --kimi "update shell completion docs"
crew new --profile standard --amp "add API pagination"
crew new --profile standard --commandcode "add a /health endpoint"
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

| Profile | Use for | OpenCode | Claude | Codex | Kimi Code | Amp | CommandCode |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `fast` | Mechanical docs, formatting, boilerplate | Luna Fast | Haiku | Luna Fast | K2.7 Code | low | DeepSeek V4 Flash |
| `standard` (default) | Normal implementation and tests | Terra | Sonnet | Terra | K2.7 Code | medium | DeepSeek V4 Pro |
| `deep` | Architecture-sensitive work, concurrency, security, difficult debugging | Sol | Opus | Sol | K3 | high | Qwen3.7-Max |

Kimi is opt-in with `--kimi`; OpenCode remains the default engine.
Kimi tasks run headlessly on both tmux and Herdr because Kimi Code does not provide a documented
way to seed a prompt into its interactive TUI.
Interactive Kimi sessions are still available with `crew new -b <branch> --kimi`.
Amp is opt-in with `--amp` and tasked Amp runs use execute mode on both backends, fixing the TUI
remaining open after a Herdr crewmate finishes.
Interactive Amp remains available with `crew new -b <branch> --amp`.
Amp `deep` uses `high`; Crew never selects `ultra` automatically.
CommandCode is opt-in with `--commandcode`. Its headless (`-p`) mode is read-only and cannot edit
or commit without `--yolo`, so tasked CommandCode crewmates run `--yolo` bounded by the required
`CREW_MANAGED`-gated guard hook (`~/.commandcode/hooks/crew-guard.sh`), which denies
push/sudo/hard-reset/clean/dangerous rm and fails closed; Crew refuses to launch one if the hook is
missing (`make restow-commandcode`). Interactive CommandCode remains available with
`crew new -b <branch> --commandcode` and never uses `--yolo`.

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
built on `git-wt` + `opencode`/`claude`/`codex`/`kimi`/`amp`/`commandcode` + `gh`.

```bash
gate init                          # optional: seed OpenCode .gate.sh overrides
gate init --engine kimi            # optional Kimi variant
gate init --engine amp             # optional Amp variant; uses medium mode
gate init --engine commandcode     # optional CommandCode variant; Qwen3.7-Max review, DeepSeek V4 Pro fixes
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

`gate init --engine amp` uses Amp `medium` mode for review, fixes, and agent-detected checks.
It applies minimal shared settings and requires the Amp workflow-guardrails plugin to reject risky
direct shell commands when no approval UI is available.
Override the execute-mode settings path with `GATE_AMP_SETTINGS`.
The guard plugin must be installed at Amp's system plugin path via `make restow-amp`.
`gate init --engine commandcode` reviews with Qwen3.7-Max in read-only `-p` mode (no `--yolo`) and
applies fixes with DeepSeek V4 Pro under `--yolo`, bounded by the required `CREW_MANAGED`-gated guard
hook; the fix stage fails closed if the hook is missing (`make restow-commandcode`).
Gate never selects Amp `high` or `ultra` modes.

The LLM only classifies findings; you approve the judgment calls (or a headless run blocks on
them), so an LLM verdict is never trusted as an exit code. Commit your work before running - the
gate validates commits, and it refuses to run on the default branch. Requires `jq` and `gh`.
`gate` inherits the shell environment you run it from. Put worktree-specific bootstrap in
`.worktrees-setup`, for example copying `.env` from `$GIT_WT_MAIN` and installing dependencies.

## check-app-updates / update-apps - non-pacman app version tracking + updates

Some desktop apps here were installed by hand instead of through pacman/AUR - AppImages dropped
under `/opt`, or a `.deb` extracted directly onto the filesystem because its packaging tool choked
(`debtap`/`namcap` crashing on modern Electron binaries, notably). `pacman -Syu` has no idea these
exist (or, for `command-code`, actively points at the wrong thing - see below). Two scripts share
per-app logic from `scripts/.local/share/manual-apps.sh`:

- **`check-app-updates`** - read-only. Compares each installed version against its real upstream
  source and reports what's stale.
- **`update-apps`** - actually updates them, the same way they were installed originally (AppImage
  replaced in place, `.deb` extracted by hand and merged onto `/` - never via `debtap`/pacman/paru).

```bash
check-app-updates              # check all known apps
check-app-updates cursor       # check just one: cursor | t3code | chatgpt | command-code

update-apps                    # interactive fzf picker (Tab = multi-select, Enter = update)
update-apps cursor t3code      # update specific apps directly, no picker
update-apps --all              # update everything that's currently outdated
```

`update-apps` prompts for sudo per app as needed (installs live under `/opt` and `/usr`). Requires
`fzf`, `curl`, `python3`, and `ar`/`tar` (binutils).

Currently covers:

- `cursor` - installed version read from the AppImage's embedded `product.json` (via
  `--appimage-extract`, no launch); latest + download URL from `cursor.com`'s own update-check API.
- `t3code` - installed version from the `X-AppImage-Version` field in
  `~/.local/share/applications/t3code.desktop` (which `update-apps` rewrites after updating); latest
  + AppImage asset from the `pingdotgg/t3code` GitHub releases API.
- `chatgpt` - installed version from `~/.local/share/chatgpt-installed-version` (a marker file,
  written by `update-apps` and updated on every reinstall, since the app's own
  `/usr/lib/chatgpt/version` uses an internal build number, not the package version); latest from
  OpenAI's own apt repo index at `persistent.oaistatic.com`.
- `command-code` (the desktop GUI app, `@commandcode/desktop` from `commandcode.ai`/
  `CommandCodeAI/desktop`) - installed version from its `resources/app/package.json`; latest + `.deb`
  asset from the `CommandCodeAI/desktop` GitHub releases API. **Important:** this app happens to be
  installed as a pacman package literally named `command-code` (from a manual `debtap` build), but
  AUR also has an unrelated npm-CLI tool under that exact same name from a different author. Pacman
  matches by name only - running `paru -S command-code` would delete this GUI app's files and
  replace them with the unrelated CLI tool. `update-apps command-code` extracts the real `.deb` by
  hand instead, same as `chatgpt`; this leaves pacman's local db reporting the old version, which is
  cosmetic only (pacman just doesn't know about the manual reinstall - nothing depends on this
  package, so it's harmless).

It's read-only - it reports, it doesn't reinstall. When it flags something outdated, redo whatever
manual install step was used originally (re-download the `.deb`/AppImage, repeat the extraction).
**If you reinstall `chatgpt`, update the marker file** (`echo <new-version> >
~/.local/share/chatgpt-installed-version`) or every future check will report a false positive.

Exits `0` if everything's current, `1` if anything is outdated or unreachable.
