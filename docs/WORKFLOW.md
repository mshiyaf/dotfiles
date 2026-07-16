# Agentic Development Workflow

A practical guide to the agentic setup in these dotfiles - **what to run when**, and **what
every piece is for**. It spans three AI coding tools (Claude Code, Codex, OpenCode) and three
stow packages (`agents/`, `opencode/`, `scripts/`).

- New here? Read **Part 1** (the mental model) once, then keep **Part 2** (playbooks) open while you work.
- Looking up a specific command/skill/config? Jump to **Part 3** (reference).
- Package-level details live in [`agents/README.md`](../agents/README.md),
  [`opencode/README.md`](../opencode/README.md), [`scripts/README.md`](../scripts/README.md).

---

## Part 1 - The mental model

### Three tools, one shared brain

| Layer | Shared across all 3? | Where it lives |
|---|---|---|
| **Instructions** (`AGENTS.md` / `CLAUDE.md`) | ✅ identical | `agents/AGENTS.md` → symlinked into each tool |
| **Skills** (31) | ✅ identical | `agents/.config/opencode/skills/` → symlinked into each tool |
| **Commands** (39 slash commands) | ❌ OpenCode only | `opencode/.config/opencode/commands/` |
| **Subagents** (10 generated roles + OpenCode built-ins) | partly | OpenCode canonical prompts → generated Claude/Codex files |
| **Config** | ❌ per-tool | `opencode.json` / Claude `settings.json` / Codex `config.toml` |

Skills are the shared command layer.
Subagent prompts are canonical in OpenCode format and generated into Claude Code and Codex formats with per-harness model maps.
OpenCode slash commands remain thin ergonomic wrappers for context injection and model routing.

### The four layers - what fires when

- **Skills** = portable *knowledge* (a checklist / lens / procedure). Available in all three
  tools. In Claude a skill is invocable as a slash (`/ceo-review`) or auto-activates by
  description; in Codex it is invocable as `$ceo-review`; in OpenCode an agent uses it as a tool. **Rule: want a capability everywhere → make it a skill.**
- **Commands** (OpenCode) = ergonomic *slash triggers* that inject context (`git diff`, `$ARGUMENTS`),
  route to a subagent (which picks the model), and usually say "use the X skill". Thin wrappers over skills.
- **Subagents** = named *roles* (`reviewer`, `critic`, `architect`…) generated for all three harnesses.
  OpenCode remains canonical for prompts and permissions; Claude/Codex get harness-specific generated files.
- **Scripts** (`scripts/.local/bin`, on `$PATH`) = plain CLI tools the human or an agent runs:
  `wt`/`git-wt` (worktrees), `crew` (parallel agents), `gate` (ship gate).

### The sprint shape

```
Think → Plan → Plan-review → Build → Review → Test → Ship → Reflect
```

### Model-routing philosophy (in `opencode.json`)

OpenCode routing is OpenAI-only.
Luna Fast handles lightweight writing, Terra handles everyday implementation, and Sol handles
reasoning-intensive planning, debugging, and review.
Sol Pro is reserved for the highest-risk security and critique work.

| Tier | Agents | Model |
|---|---|---|
| Workhorse | `build`, `tester`, `crewmate` | `openai/gpt-5.6-terra` |
| Planning | `plan`, `architect`, `refactor-planner` | `openai/gpt-5.6-sol` |
| Debugging / review | `debugger`, `reviewer` | `openai/gpt-5.6-sol` |
| Security / critique | `security-reviewer`, `critic` | `openai/gpt-5.6-sol-pro` |
| Writing | `docs-writer`, `pr-writer` | `openai/gpt-5.6-luna-fast` |
| Research | `researcher` | `openai/gpt-5.6-sol-fast` |
| Orchestration | `captain` | `openai/gpt-5.6-terra-fast` |

`small_model = openai/gpt-5.6-luna-fast` (lightweight ops); `default_agent = build`.
On-demand escalation: `/claude-review` shells out to the `claude` CLI (your Claude subscription)
for a different-family second opinion - spend only when you ask.

Generated Claude/Codex model map:

| Role | OpenCode | Claude | Codex |
|---|---|---|---|
| `reviewer` | gpt-5.6-sol | opus | gpt-5.6-sol |
| `security-reviewer`, `critic` | gpt-5.6-sol-pro | opus | gpt-5.6-sol-pro |
| `architect`, `refactor-planner` | gpt-5.6-sol | opus | gpt-5.6-sol |
| `researcher` | gpt-5.6-sol-fast | sonnet | gpt-5.6-sol-fast |
| `debugger` | gpt-5.6-sol | sonnet | gpt-5.6-sol |
| `tester` | gpt-5.6-terra | sonnet | gpt-5.6-terra |
| `docs-writer`, `pr-writer` | gpt-5.6-luna-fast | haiku | gpt-5.6-luna-fast |

---

## Part 2 - Playbooks

Each step names the exact command (OpenCode `/slash`) or skill, and the model that runs it.
In Claude/Codex, use the same-named skill instead of the slash command.

### 1. Planning a product

*Goal: decide whether and what to build before designing anything.*

1. `/research <topic>` - gather live context (researcher · gpt-5.6-sol-fast).
2. `/autoplan <idea>` or `/agentic-plan` - end-to-end plan draft (architect · gpt-5.6-sol).
3. `/plan-ceo-review <the idea>` - founder lens: is the problem real, who's the user, what to
   cut, stronger alternatives (critic · gpt-5.6-sol-pro). **Framing before features.**
4. Capture the agreed scope + non-goals in the repo's `AGENTS.md` (seed with `/init-agents-md`).

### 2. Client proposal / estimation

*Goal: turn requirements into commercially safe estimates and proposal text without hiding scope risk.*

1. `/effort-estimate <requirement>` - structured effort, timeline, and cost estimate. Defaults to INR unless another currency is specified.
2. `/proposal-draft <requirement or notes>` - draft a business proposal from requirements, notes, or sample references.
3. `/proposal-review <proposal path or text>` - review clarity, missing sections, scope ambiguity, assumptions, exclusions, and timeline consistency.
4. `/proposal-commercial-review <proposal path or text>` - review pricing, AMC, hosting, payment terms, third-party costs, add-ons, and commercial risk.
5. `/proposal-prototype <proposal path or text>` - create a prototype plan, HTML prototype, or image prompts from the reviewed proposal for the initial client conversation.
6. Use `/plan-eng-review` for complex technical feasibility and `/plan-ceo-review` for final business/scope sanity before sending numbers.

### 3. Planning a feature

*Goal: a locked, reviewed implementation plan - no code yet.*

1. `/plan-feature <feature>` - implementation plan (architect · gpt-5.6-sol).
2. `/plan-eng-review` - architecture, data flow, edge cases, tests, failure modes (architect).
3. `/plan-design-review` - if there's UI: flow, design-system fit, a11y, AI-slop (architect).
4. `/plan-ceo-review` - scope/value gut-check (critic).
5. Lock the plan; only then build.

### 4. Building

*Goal: implement in small, isolated, repo-patterned changes.*

1. Work on the default `build` agent (gpt-5.6-terra).
2. Use the **`grounding`** skill when touching unfamiliar APIs/versions - forces verification
   against real code instead of hallucinating signatures.
3. Isolate the work in a worktree so it never disturbs your main checkout → **Playbook 10**.

### 5. Fixing a bug

*Goal: reproduce first, then fix, then prove it's fixed.*

1. `/investigate <bug>` or `/debug-tests` - root-cause first, using the **`systematic-debugging`**
   skill (debugger · gpt-5.6-sol). **Reproduce before fixing.**
2. Fix on the `build` agent.
3. `/qa-only` - exercise the changed behavior, report what still breaks (tester).
4. `/review-diff` - catch regressions (reviewer · gpt-5.6-sol).
5. `/second-pass <prior findings>` - after fixes, confirm resolved + no new regressions (reviewer).

### 6. Refactoring

1. `/refactor-plan <target>` - safe sequencing + verification points (refactor-planner · gpt-5.6-sol).
2. Apply in small steps on `build`.
3. `/review-diff` and run the tests after each step.

### 7. Reviewing a change (human-in-the-loop)

*Goal: deep review before you hand off to the gate.*

1. `/review-diff` (unstaged+staged) or `/review-staged` (pre-commit) - correctness/regressions (reviewer).
2. `/security-review` - auth, data handling, dependencies, risky code (security-reviewer · gpt-5.6-sol-pro).
3. `/ui-review` - if UI: visual hierarchy, states, tokens (reviewer + frontend-design skill).
4. `/ceo-review` - is this the right change / right scope (critic).
5. `/claude-review` - independent second opinion via the `claude` CLI (reviewer → Claude).
6. `/second-pass` - after you apply fixes, re-check.
7. `/long-context-review` - for very large diffs spanning many files.

### 8. Testing

1. `/test-plan <change>` - a practical test plan (tester).
2. Write tests with the **`test-writer`** skill, or **`test-driven-development`** when a failing
   test can define the behavior first.
3. `/qa-only` - behavior testing without code changes; for web use the **`browser`** skill
   (headless: fetch text, screenshot, click, fill, assert, axe a11y).

### 9. Reflect

- `/critique` or `/second-opinion` - an independent gut-check on your analysis or a review, to
  surface what the first pass missed (critic · gpt-5.6-sol-pro).

### Playbook 10 - Parallel multi-agent development (`wt` + `crew`)

*Run several agents at once, each fully isolated, without them clobbering each other.*

**`wt` - one isolated checkout.** Use when you want a single agent on its own branch without
touching your main working tree.

```bash
wt "add a dark-mode toggle"  # AI-name a branch, create <repo>.worktrees/<name> and cd in
opencode                     # (or claude) - the agent works here, isolated
git wt rm <branch> -D        # teardown: remove worktree + branch
```

`wt` is task-first: describe the work and the branch is AI-named (via `ai-branch-name`,
printed as `-> branch: ...`). Use `wt <existing>` to cd into an existing worktree, or
`wt -b <name> [start]` to force a specific branch. Tab completion covers all three.

Worktrees are **siblings** of the repo (`<repo>.worktrees/<branch>`), never nested inside it, so
they're never committed or scanned. If an executable **`.worktrees-setup`** exists at the repo
root, `wt`/`git wt new` runs it inside the new worktree (copy `.env`, install deps, warm caches).

**`crew` - many agents at once.** Our lightweight orchestrator (our own take on firstmate - no
external scripts). Each crewmate = a branch in its own `wt` worktree running an agent in its own
detached **tmux session or background herdr workspace** (backend auto-detected at spawn: herdr
inside herdr, tmux otherwise; `CREW_BACKEND=tmux|herdr` forces one). On herdr a task launches the
engine's interactive TUI seeded with the task, so herdr tracks live agent status
(working/blocked/idle); `--headless` keeps the tmux-style bounded run.
A crewmate with a task runs **bounded**: it may edit, run tests, and
commit on its branch, then stops - it never pushes. Each engine is constrained differently but to
the same effect - auto-approve everything except an explicit deny-list, never a full yolo mode:
`opencode` via `--agent crewmate --auto` (auto-approves, but the `crewmate` agent still denies
`git push`/`sudo`/hard-reset); `claude` via `--permission-mode acceptEdits` + a
`git push`/`sudo`/hard-reset deny-list; `codex` via the `workspace-write` sandbox (network off, so
push is blocked). Headless `opencode run` has no TTY to approve prompts, so **`--auto` is required**
or every crewmate action is auto-rejected.

```bash
crew new "<task>"            # standard profile (the default): AI-name a branch, then worktree + session/workspace running:
                             #   opencode run "<task>" --agent crewmate
                              #   --profile fast|standard|deep -> explicit per-engine model tier
                              #   -b/--branch <name> -> force/reuse a branch (no task -> interactive)
                             #   --claude / --codex -> use claude or codex (bounded the same way)
                             #   --attach  -> jump into the session now
                             #   --start <ref> -> branch from <ref>
crew status [<branch>]       # table: branch | running/done(rc) | commits-ahead | last log line
crew logs <branch> [-f]      # print (or -f follow) a crewmate's captured output
crew watch [-n SECS]         # notify (bell + notify-send) when a crewmate finishes or blocks
crew ls                      # list active crew sessions / workspaces
                             #   status/watch/ls take --all to span every repo (default: this repo)
crew attach <branch>         # attach / switch-client to a crewmate
crew stop <branch> -D        # kill the session (-D also removes worktree + branch)
```

**crew is scoped per repository.** Sessions and state are namespaced by a repo key (derived from
the shared `--git-common-dir`, so it is identical from the main repo or any of its worktrees).
`crew ls`/`status`/`watch` therefore show only the current repo's crewmates - two different repos can
each run a `feat-x` crewmate without colliding. Pass `--all` for the cross-repo view. Per-crewmate
state lives in `~/.local/state/crew/<repo-key>/<branch>/` (`branch`, `worktree`, `session`, `task`,
`log`, `status`), which is what `crew status`/`crew logs` read and `crew stop` clears.

**Two ways to drive it:**

*Manual* - you run `crew` yourself and check in when you like:

```bash
crew new "fix the flaky login test"        # -> branch: fix/flaky-login (AI-named)
crew new "add a dark-mode toggle to settings"
crew status                   # see both: running -> done:0 with commits-ahead
crew logs fix/flaky-login     # read what a crewmate did (or -f to follow)
# when each shows done with commits: review the branch (Playbook 7), ship via the gate (Playbook 11)
crew stop fix/flaky-login -D
```

*Captain-driven* - converse with **one** agent that dispatches and monitors for you (the firstmate
feel). `/crew` routes to the **`captain` agent**, which uses the `crew` skill:

```bash
/crew "add a dark-mode toggle, fix the flaky login test, and add a /health endpoint"
```

The captain splits the request into independent features, runs `crew new` per feature, reports what
it dispatched, then **stops** and hands control back. It does not sit in a polling loop; ask it to
check in and it runs `crew status`/`crew logs` **once**, surfaces any `BLOCKED:` reason, and tells
you which branches are `done` with commits - **ready for review**. The captain never edits code,
pushes, or merges; it hands the ready branches back to you.

Crew profiles select explicit models for every engine rather than inheriting machine defaults:

| Profile | Use for | OpenCode | Claude | Codex |
|---|---|---|---|---|
| `fast` | Mechanical documentation, formatting, boilerplate | Luna Fast | Haiku | Luna Fast |
| `standard` | Normal implementation and tests | Terra | Sonnet | Terra |
| `deep` | Architecture-sensitive work, concurrency, security, difficult debugging | Sol | Opus | Sol |

The captain assigns profiles explicitly: `fast` for mechanical tasks, `standard` for normal work,
and `deep` only when stronger reasoning is justified.

**Hands-off alerts (`crew watch`).** The captain has no background loop, so between your check-ins it
is idle - "report on request" is deliberate, not laziness. If you want to be *pushed* an alert the
moment a crewmate finishes or blocks, run `crew watch` in its own pane. It tails the state dir, costs
zero tokens, and fires a terminal bell + `notify-send` toast only on a real transition
(ready / blocked / crashed), e.g. `crew: feat-dark ready for review - done, 2 commit(s)`. That is the
event-driven layer an in-chat agent cannot provide on its own.

**How agnostic is this?** The engine (`crew` CLI, worktrees, tmux/herdr, state tracking) is fully
tool-agnostic - dispatch `opencode`, `claude`, or `codex` crewmates from any terminal, all bounded
the same way. The `crew` **skill** is shared across all three tools, so any of them can play captain.
Only the packaged `/crew` **command** and the `captain`/`crewmate` **agent** definitions are
OpenCode-specific (commands and agents are per-tool). From **Claude**, get the same captain by
invoking the `crew` skill - it surfaces as `/crew` (or just ask Claude to "use the crew skill to
build A, B, C"); Claude then drives the same `crew` CLI. From **Codex**, invoke `$crew`.

**When to use which:** one focused task → `wt`; several independent tasks you want running
(semi-)unattended → `crew` (manual) or `/crew` (captain-driven). Native alternatives if you prefer
Claude's own: `claude --tmux`, `claude --bg`.

**Guardrails:** every worktree is fully isolated, so parallel agents never collide. Crewmates commit
but never push; the captain never pushes or merges. Always review each ready branch and run it
through the gate before merging - a `done:0` means the crewmate committed, not that the work is right.
Features must be **independent**: crewmates do not coordinate edits to shared files, so merge or
sequence any tasks that would touch the same core files.

### Playbook 11 - Shipping through the gate (our no-mistakes alternative)

*`gate` validates committed work in a disposable worktree and only pushes + opens a PR once it
passes. Our self-owned version of no-mistakes - no external binary; built on `git-wt` + the coding
agent + `gh`.*

**Optional deterministic overrides:**

```bash
/init-gate        # (or: gate init) writes optional .gate.sh overrides
```

`gate run` works without `.gate.sh`.
When `GATE_TEST` or `GATE_LINT` is empty, the build agent detects and runs relevant checks.
When `GATE_DOCS` is empty, docs are skipped by default.
Use `.gate.sh` (plain sourced bash, not YAML) only for deterministic overrides:
`GATE_TEST`, `GATE_DOCS`, `GATE_LINT`, `GATE_REVIEW_CMD` (structured JSON review; empty to skip),
`GATE_REVIEW_APPROVE` (1 = gate `ask_user` findings, 0 = informational), `GATE_FIX_CMD` (how auto-fixes
are requested), `GATE_MAX_ROUNDS`, `GATE_EVIDENCE_DIR`, `GATE_WATCH_CI`, `GATE_PUSH_REMOTE`.
The default OpenCode fix command uses `--auto` inside the disposable gate worktree; dangerous commands
remain denied by `opencode.json`.

`gate` inherits the shell environment you run it from.
Put worktree-specific bootstrap in `.worktrees-setup`, for example:

```bash
#!/usr/bin/env bash
cp "$GIT_WT_MAIN/.env" . 2>/dev/null || true
pnpm install --frozen-lockfile
```

**Ship a branch:**

```bash
# commit your work first - the gate validates commits, not the dirty tree
/ship-gate        # (or: gate run [branch])
```

Pipeline:

1. Copies the branch HEAD into a **disposable worktree** - your working tree is untouched.
2. **review** - *structured*: the reviewer emits JSON findings classified `auto_fix` vs
   `ask_user`. `auto_fix` findings are applied automatically; `ask_user` findings are a **human-approval
   gate** - prompted interactively (approve / fix / block), or **blocked** when headless
   (`GATE_REVIEW_APPROVE=0` makes them informational). Evidence is written under `GATE_EVIDENCE_DIR`.
   The LLM only classifies; you decide, so we still never trust an LLM verdict as an exit code.
3. **test** → **docs** → **lint** - explicit commands run with a bounded auto-fix loop; empty
   test/lint delegates detection and validation to the build agent, while empty docs is skipped.
4. All green → fast-forward your local branch, push the validated commits, `gh pr create`.
5. **CI monitor** (opt-in, `GATE_WATCH_CI=1`): watch the PR's checks; on failure, pull the failing
   logs, auto-fix, push, and re-watch, bounded by `GATE_MAX_ROUNDS`.
6. Can't fix within the cap (or a blocked review) → **escalates**: nothing is pushed, and the
   disposable worktree is kept for you to inspect.

**How it fits with reviews:** the gate's structured review auto-fixes the mechanical stuff and makes
you approve the judgment calls, but the deep human-in-the-loop review (Playbook 7 - `ceo-review`,
`security-review`, `claude-review`, `second-pass`) still happens **before** you run the gate. The gate
then enforces the mechanical bar (tests + docs + lint), opens the PR, and (opt-in) babysits CI.
**No yolo:** push/PR happen only after every enforced stage passes, `ask_user` findings block a
headless run, and the gate refuses to run on the default branch.

**Parity note:** this closes the gaps with Kun Chen's no-mistakes on *workflow* (docs stage, structured
auto-fix/ask-user review with evidence, CI monitor). We deliberately keep the *tech stack* different -
a ~350-line bash script, not a Go binary or git-proxy - so a plain `git push` still bypasses it (run
`/ship-gate` to gate).

---

## Part 3 - Reference

### Commands (40) - OpenCode `/slash`, grouped by stage

Each routes to a subagent (which fixes the model) and usually uses the linked skill.

| Command | Agent (model) | Uses skill | Purpose |
|---|---|---|---|
| `/research` | researcher (gpt-5.6-sol-fast) | research | Research a topic using live web sources |
| `/explain` | debugger (gpt-5.6-sol) | explain | Explain code, behavior, or repo structure |
| `/investigate` | debugger (gpt-5.6-sol) | investigate | Investigate a bug/failure before proposing fixes |
| `/autoplan` | architect (gpt-5.6-sol) | autoplan | End-to-end implementation plan, no edits |
| `/plan-feature` | architect (gpt-5.6-sol) | autoplan | Plan a feature implementation, no changes |
| `/effort-estimate` | architect (gpt-5.6-sol) | effort-estimate | Structured effort, timeline, and cost estimate |
| `/architecture-check` | architect (gpt-5.6-sol) | api-design, refactor-planner | Architecture review of a design/change |
| `/agentic-plan` | architect (gpt-5.6-sol) | autoplan | Plan an agentic workflow (subagents, tools, orchestration) |
| `/refactor-plan` | refactor-planner (gpt-5.6-sol) | refactor-planner | Safe refactor plan with sequencing + verification |
| `/plan-ceo-review` | critic (gpt-5.6-sol-pro) | ceo-review | Founder-lens review of a **plan** |
| `/plan-design-review` | architect (gpt-5.6-sol) | design-review | Plan-stage UX/design-system/a11y review |
| `/plan-eng-review` | architect (gpt-5.6-sol) | eng-review | Plan-stage architecture/edge-case/test review |
| `/proposal-draft` | docs-writer (gpt-5.6-luna-fast) | proposal-writing | Draft a client proposal from requirements or notes |
| `/proposal-review` | critic (gpt-5.6-sol-pro) | proposal-writing, ceo-review | Review proposal clarity, scope safety, and consistency |
| `/proposal-commercial-review` | critic (gpt-5.6-sol-pro) | proposal-writing, effort-estimate, ceo-review | Review pricing, AMC, hosting, payment terms, and commercial risk |
| `/proposal-prototype` | docs-writer (gpt-5.6-luna-fast) | prototyping-proposals, proposal-writing, frontend-design | Create proposal-aligned prototype plans, HTML prototypes, or image prompts |
| `/review-diff` | reviewer (gpt-5.6-sol) | code-review | Review unstaged+staged diffs for bugs/regressions |
| `/review-staged` | reviewer (gpt-5.6-sol) | code-review | Review only staged changes pre-commit |
| `/long-context-review` | reviewer (gpt-5.6-sol) | code-review | Review across many files / a long diff |
| `/ui-review` | reviewer (gpt-5.6-sol) | frontend-design | Visual/UI review of implemented components |
| `/ship-check` | reviewer (gpt-5.6-sol) | - | Final readiness review before merge/release |
| `/security-review` | security-reviewer (gpt-5.6-sol-pro) | security-review | Security review of changes + nearby risky code |
| `/ceo-review` | critic (gpt-5.6-sol-pro) | ceo-review | Founder-lens review of a **change/diff** |
| `/second-opinion` | critic (gpt-5.6-sol-pro) | critique | Independent second opinion on a plan/diff/review |
| `/critique` | critic (gpt-5.6-sol-pro) | critique | Critique of recent analysis/review |
| `/claude-review` | reviewer → `claude` CLI | - | Second opinion from the Claude CLI (your Claude sub) |
| `/second-pass` | reviewer (gpt-5.6-sol) | second-pass | Re-review after fixes; confirm resolved, no regressions |
| `/test-plan` | tester (gpt-5.6-terra) | test-writer | Practical test plan for a change/feature |
| `/qa-only` | tester (gpt-5.6-terra) | - | Test changed behavior, report bugs, no code changes |
| `/debug-tests` | debugger (gpt-5.6-sol) | debugging | Debug failing tests, root-cause first |
| `/crew` | captain (gpt-5.6-terra-fast) | crew | Dispatch a crewmate per feature, monitor, report ready branches |
| `/gate-review` | reviewer (gpt-5.6-sol) | gate-review | Structured JSON review for the gate (auto_fix vs ask_user) |
| `/ship-gate` | build → `gate` | ship-gate | Validate in a disposable worktree, then push + PR |
| `/commit` | pr-writer (gpt-5.6-luna-fast) | git-commit | Commit staged changes (this repo or child repos) |
| `/commit-message` | pr-writer (gpt-5.6-luna-fast) | git-commit | Draft a commit message (never commits) |
| `/branch-name` | pr-writer (gpt-5.6-luna-fast) | - | Suggest short branch names from worktree context |
| `/changelog` | pr-writer (gpt-5.6-luna-fast) | release-notes | Draft changelog/release notes from commits+diffs |
| `/pr-body` | pr-writer (gpt-5.6-luna-fast) | pull-request | Draft a PR title + body from branch changes |
| `/docs-update` | docs-writer (gpt-5.6-luna-fast) | documentation | Update docs/README from current changes |
| `/init-agents-md` | build (gpt-5.6-terra) | init-agents-md | Seed a per-project `AGENTS.md` (+ `CLAUDE.md` symlink) |
| `/init-gate` | build (gpt-5.6-terra) | - | Seed optional `.gate.sh` ship-gate overrides |

### Skills (32) - shared across Claude, Codex, OpenCode

| Skill | For | Used by |
|---|---|---|
| `ceo-review` | Founder lens: framing, scope, value, alternatives | `/ceo-review`, `/plan-ceo-review` |
| `design-review` | UI/UX review: flow, tokens, a11y, AI-slop | `/plan-design-review` |
| `eng-review` | Architecture, edge cases, failure modes, tests | `/plan-eng-review` |
| `second-pass` | Re-review after fixes | `/second-pass` |
| `code-review` | Findings-first correctness/regression review | `/review-diff`, `/review-staged`, `/long-context-review` |
| `security-review` | Security review checklist | `/security-review` |
| `database-review` | Schema/migration/query/index review | (architect/reviewer) |
| `api-design` | HTTP API / interface / schema review | `/architecture-check` |
| `frontend-design` | Building UI: layout, a11y, responsive | `/ui-review` |
| `effort-estimate` | Structured effort, timeline, cost, budget, and phase estimates | `/effort-estimate`, `/proposal-commercial-review` |
| `proposal-writing` | Client proposal drafting/review: scope, commercials, AMC, payment terms, assumptions, exclusions | `/proposal-draft`, `/proposal-review`, `/proposal-commercial-review` |
| `prototyping-proposals` | Proposal-aligned prototype plans, HTML prototypes, image briefs, and image-generation prompts | `/proposal-prototype` |
| `debugging` | Lightweight diagnosis (escalates to systematic) | `/debug-tests` |
| `systematic-debugging` | Root-cause investigation | `/investigate` |
| `test-writer` | Create/update/review tests | `/test-plan` |
| `test-driven-development` | Failing-test-first for behavior changes | (build/tester) |
| `refactor-planner` | Plan safe incremental refactors | `/refactor-plan`, `/architecture-check` |
| `grounding` | Verify APIs/versions instead of hallucinating | (build) |
| `git-commit` | Conventional-commit messages | `/commit`, `/commit-message` |
| `pull-request` | PR title/body/test-plan | `/pr-body` |
| `release-notes` | Changelogs / release notes | `/changelog` |
| `documentation` | READMEs, docs, setup instructions | `/docs-update` |
| `ship-gate` | Drive the `gate` CLI + optional `.gate.sh` overrides | `/ship-gate` |
| `gate-review` | Structured JSON review for the ship gate (auto_fix vs ask_user) | `/gate-review`, `gate` |
| `crew` | Orchestrate parallel crewmates: split, dispatch, monitor, report | `/crew` |
| `browser` | Headless web QA (`browser-cli.ts`) | (any agent) |
| `find-skills` | Find/evaluate public skills before installing | (any agent) |
| `autoplan` | End-to-end implementation, feature, and agentic workflow plans | `/autoplan`, `/plan-feature`, `/agentic-plan` |
| `investigate` | Read-only bug/failure investigation before fixes | `/investigate` |
| `research` | External/web research with citations | `/research` |
| `critique` | Adversarial second opinion | `/critique`, `/second-opinion` |
| `explain` | Explain code/behavior with file references | `/explain` |
| `init-agents-md` | Bootstrap per-repo `AGENTS.md` and `CLAUDE.md` symlink | `/init-agents-md` |

Available everywhere: in **Claude** as `/skill-name` or auto-activated; in **OpenCode** invoked by
agents (governed by each agent's `skill:` allowlist in its `.md`); in **Codex** as `$skill-name` from `~/.codex/skills`.

### Subagents - three harnesses

Canonical prompts live in `opencode/.config/opencode/agents/*.md`.
Run `make agents-sync` to regenerate `agents/.claude/agents/*.md` and `agents/.codex/agents/*.toml` from those prompts plus `agents/models.json`.
Run `agents-sync --check` to verify generated files are current.

Claude Code reads `~/.claude/agents/*.md`.
Codex reads `~/.codex/agents/*.toml`.
OpenCode reads `~/.config/opencode/agents/*.md` unchanged.

| Agent | Model | Role | Can edit? |
|---|---|---|---|
| `architect` | gpt-5.6-sol | Architecture / plan reviews | no |
| `debugger` | gpt-5.6-sol | Investigate bugs / failing tests | limited |
| `tester` | gpt-5.6-terra | Test plans / QA, no code changes | no |
| `reviewer` | gpt-5.6-sol | Code/UI/ship review, findings-first | no (deny) |
| `security-reviewer` | gpt-5.6-sol-pro | Security review | no |
| `docs-writer` | gpt-5.6-luna-fast | Docs / README | docs only |
| `pr-writer` | gpt-5.6-luna-fast | Commits, PR bodies, changelogs | commit-scope |
| `refactor-planner` | gpt-5.6-sol | Refactor planning | no |
| `researcher` | gpt-5.6-sol-fast | Live web research | no |
| `critic` | gpt-5.6-sol-pro | Founder/critique/second-opinion | no |

OpenCode built-ins `build` and `plan` still live in `opencode.json`.
Generated Claude/Codex roles cover the 10 custom subagents above.

**Orchestration agents (OpenCode-only, for `crew`):**

| Agent | Model | Role | Can edit? |
|---|---|---|---|
| `captain` | gpt-5.6-terra-fast | Split a request, dispatch/monitor crewmates via the `crew` skill | no (deny) |
| `crewmate` | profile-selected | Implement one task headless in a worktree and commit; never push | yes (bounded) |

These two exist only in `opencode/.config/opencode/agents/` (they drive `crew`, which is OpenCode's
headless runner) and are not generated for Claude/Codex.

### Scripts (`scripts/.local/bin`, on `$PATH`)

| Tool | Subcommands | Purpose |
|---|---|---|
| `git wt` / `wt` | `new`, `ls`, `path`, `rm`, `prune` | Sibling worktrees; `wt` adds `cd`; `.worktrees-setup` post-create hook |
| `crew` | `new`, `status`, `logs`, `watch`, `ls`, `attach`, `stop` | tmux/herdr multi-agent orchestrator over `wt`; tasks run bounded (`--agent crewmate --auto`) + track completion; `watch` pushes alerts; `--claude`/`--codex`/`--headless` |
| `gate` | `init`, `run`, `status` | Ship gate: structured review (auto-fix/ask-user + evidence) → test → docs → lint → push → PR → CI monitor; `init --engine opencode|claude|codex` |
| `codex-status` | `--json`, `--watch` | ChatGPT/Codex usage + rate-limit meter |

Full usage: [`scripts/README.md`](../scripts/README.md).

### Config files - what each controls, who reads it

| File | Read by | Controls |
|---|---|---|
| `~/AGENTS.md` (→ `agents/AGENTS.md`) | all 3 tools | Global behavioral instructions (short, shared) |
| `opencode.json` | OpenCode | Model routing (`agent` block), providers, `small_model`, global permissions |
| `tui.json` | OpenCode TUI | Theme (`noctalia`) + local plugins (`./codex-status.ts` usage meter) |
| Claude `settings.json` | Claude Code | Model, enabled plugins, marketplaces, permissions, statusline |
| Codex `config.toml` | Codex | Model, per-project trust levels, features; not stowed |
| Codex `rules/default.rules` | Codex | Exec-policy allow/forbid rules for shell approvals |
| `.gate.sh` (per repo, optional) | `gate` | Deterministic ship-gate overrides; empty test/lint uses auto-detection |
| `.worktrees-setup` (per repo) | `git wt` | Post-create hook run inside each new worktree |
| project `AGENTS.md` (per repo) | all 3 tools | Project-specific stack, commands, conventions, pitfalls |

`codex-status.ts` is a **local** OpenCode TUI plugin (needs `bun`) that renders your ChatGPT/Codex
usage % in the status bar; the standalone `codex-status` CLI prints the same on demand.

---

## Part 4 - Cross-tool cheatsheet

**Same capability, three tools** (skills are shared; only the trigger differs):

| Capability | Claude Code | OpenCode | Codex |
|---|---|---|---|
| CEO review | `ceo-review` skill (`/ceo-review` or ask) | `/ceo-review` (→ critic) | `$ceo-review` skill |
| Design review | `design-review` skill | `/plan-design-review` / `/ui-review` | `$design-review` skill |
| Eng review | `eng-review` skill | `/plan-eng-review` / `/architecture-check` | `$eng-review` skill |
| Code review | `code-review` skill | `/review-diff` | `$code-review` skill |
| Re-review | `second-pass` skill | `/second-pass` | `$second-pass` skill |
| Ship gate | run `gate run` | `/ship-gate` | run `gate run` |
| Web QA | `browser` skill | `browser` skill | `browser` skill |

**Rule of thumb:** want a capability in every tool → make it a **skill**. Want a slash trigger with
model routing → add an OpenCode **command** that uses the skill.

### Verify your setup

```bash
# generated subagents are current
make agents-sync && git diff --exit-code agents/
agents-sync --check

# skills present in OpenCode (and no duplicates)
opencode debug skill | grep '"name"' | sort | uniq -d      # prints nothing = no dupes

# in Claude Code: /reload-skills  → should list your user skills

# shared symlinks resolve to one canonical source
readlink -f ~/AGENTS.md ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.config/opencode/AGENTS.md | sort -u
readlink -f ~/.claude/skills ~/.codex/skills                # -> the shared skills dir
readlink -f ~/.claude/settings.json ~/.claude/agents/reviewer.md ~/.codex/agents/reviewer.toml
test -L ~/.claude/settings.json

# scripts on PATH
command -v wt git-wt crew gate claude-statusline
```
