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
| **Skills** (28) | ✅ identical | `agents/.config/opencode/skills/` → symlinked into each tool |
| **Commands** (34 slash commands) | ❌ OpenCode only | `opencode/.config/opencode/commands/` |
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
GPT-5.5 handles coding, planning, debugging, testing, review, and critique.
Mini/nano variants are kept for lighter writing and small-model operations.

| Tier | Agents | Model |
|---|---|---|
| Workhorse | `build`, `debugger`, `tester` | `openai/gpt-5.5` |
| Planning | `plan`, `architect`, `refactor-planner` | `openai/gpt-5.5` |
| Review | `reviewer`, `security-reviewer` | `openai/gpt-5.5` |
| Writing | `docs-writer`, `pr-writer` | `openai/gpt-5.4-mini` |
| Research | `researcher` | `openai/gpt-5.5-fast` |
| Challenge | `critic` | `openai/gpt-5.5` |

`small_model = openai/gpt-5.4-nano` (lightweight ops); `default_agent = build`.
On-demand escalation: `/claude-review` shells out to the `claude` CLI (your Claude subscription)
for a different-family second opinion - spend only when you ask.

Generated Claude/Codex model map:

| Role | OpenCode | Claude | Codex |
|---|---|---|---|
| `reviewer`, `security-reviewer` | gpt-5.5 | opus | gpt-5.5 |
| `critic` | gpt-5.5 | opus | gpt-5.5 |
| `architect`, `refactor-planner` | gpt-5.5 | opus | gpt-5.5 |
| `researcher` | gpt-5.5-fast | sonnet | gpt-5.5-fast |
| `debugger`, `tester` | gpt-5.5 | sonnet | gpt-5.1-codex-max |
| `docs-writer`, `pr-writer` | gpt-5.4-mini | haiku | gpt-5.4-mini |

---

## Part 2 - Playbooks

Each step names the exact command (OpenCode `/slash`) or skill, and the model that runs it.
In Claude/Codex, use the same-named skill instead of the slash command.

### 1. Planning a product

*Goal: decide whether and what to build before designing anything.*

1. `/research <topic>` - gather live context (researcher · gpt-5.5-fast).
2. `/autoplan <idea>` or `/agentic-plan` - end-to-end plan draft (architect · gpt-5.5).
3. `/plan-ceo-review <the idea>` - founder lens: is the problem real, who's the user, what to
   cut, stronger alternatives (critic · gpt-5.5). **Framing before features.**
4. Capture the agreed scope + non-goals in the repo's `AGENTS.md` (seed with `/init-agents-md`).

### 2. Planning a feature

*Goal: a locked, reviewed implementation plan - no code yet.*

1. `/plan-feature <feature>` - implementation plan (architect · gpt-5.5).
2. `/plan-eng-review` - architecture, data flow, edge cases, tests, failure modes (architect).
3. `/plan-design-review` - if there's UI: flow, design-system fit, a11y, AI-slop (architect).
4. `/plan-ceo-review` - scope/value gut-check (critic).
5. Lock the plan; only then build.

### 3. Building

*Goal: implement in small, isolated, repo-patterned changes.*

1. Work on the default `build` agent (gpt-5.5).
2. Use the **`grounding`** skill when touching unfamiliar APIs/versions - forces verification
   against real code instead of hallucinating signatures.
3. Isolate the work in a worktree so it never disturbs your main checkout → **Playbook 9**.

### 4. Fixing a bug

*Goal: reproduce first, then fix, then prove it's fixed.*

1. `/investigate <bug>` or `/debug-tests` - root-cause first, using the **`systematic-debugging`**
   skill (debugger · gpt-5.5). **Reproduce before fixing.**
2. Fix on the `build` agent.
3. `/qa-only` - exercise the changed behavior, report what still breaks (tester).
4. `/review-diff` - catch regressions (reviewer · gpt-5.5).
5. `/second-pass <prior findings>` - after fixes, confirm resolved + no new regressions (reviewer).

### 5. Refactoring

1. `/refactor-plan <target>` - safe sequencing + verification points (refactor-planner · gpt-5.5).
2. Apply in small steps on `build`.
3. `/review-diff` and run the tests after each step.

### 6. Reviewing a change (human-in-the-loop)

*Goal: deep review before you hand off to the gate.*

1. `/review-diff` (unstaged+staged) or `/review-staged` (pre-commit) - correctness/regressions (reviewer).
2. `/security-review` - auth, data handling, dependencies, risky code (security-reviewer · gpt-5.5).
3. `/ui-review` - if UI: visual hierarchy, states, tokens (reviewer + frontend-design skill).
4. `/ceo-review` - is this the right change / right scope (critic).
5. `/claude-review` - independent second opinion via the `claude` CLI (reviewer → Claude).
6. `/second-pass` - after you apply fixes, re-check.
7. `/long-context-review` - for very large diffs spanning many files.

### 7. Testing

1. `/test-plan <change>` - a practical test plan (tester).
2. Write tests with the **`test-writer`** skill, or **`test-driven-development`** when a failing
   test can define the behavior first.
3. `/qa-only` - behavior testing without code changes; for web use the **`browser`** skill
   (headless: fetch text, screenshot, click, fill, assert, axe a11y).

### 8. Reflect

- `/critique` or `/second-opinion` - an independent gut-check on your analysis or a review, to
  surface what the first pass missed (critic · gpt-5.5).

### Playbook 9 - Parallel multi-agent development (`wt` + `crew`)

*Run several agents at once, each fully isolated, without them clobbering each other.*

**`wt` - one isolated checkout.** Use when you want a single agent on its own branch without
touching your main working tree.

```bash
wt feature-x            # create sibling worktree <repo>.worktrees/feature-x and cd in
opencode                # (or claude) - the agent works here, isolated
git wt rm feature-x -D  # teardown: remove worktree + branch
```

Worktrees are **siblings** of the repo (`<repo>.worktrees/<branch>`), never nested inside it, so
they're never committed or scanned. If an executable **`.worktrees-setup`** exists at the repo
root, `wt`/`git wt new` runs it inside the new worktree (copy `.env`, install deps, warm caches).

**`crew` - many agents at once.** Our lightweight orchestrator (our own take on firstmate - no
external scripts). Each crewmate = a branch in its own `wt` worktree running an agent in its own
detached **tmux** session.

```bash
crew new <branch> "<task>"   # worktree + tmux session running: opencode run "<task>" --agent build
                             #   no task   -> interactive opencode in the worktree
                             #   --claude / --codex -> use claude or codex instead
                             #   --attach  -> jump into the session now
                             #   --start <ref> -> branch from <ref>
crew ls                      # list active crew sessions
crew attach <branch>         # attach / switch-client to a crewmate
crew stop <branch> -D        # kill the session (-D also removes worktree + branch)
```

**Worked example - a bug fix and a feature in parallel:**

```bash
crew new fix/login    "fix the flaky login test"
crew new feat/dark    "add a dark-mode toggle to settings"
crew ls                       # see both running
crew attach fix/login         # check in on one; detach and check the other
# when each is done: review the branch (Playbook 6), ship via the gate (Playbook 10)
crew stop fix/login -D
```

**When to use which:** one focused task → `wt`; two or more independent tasks you want running
(semi-)unattended → `crew`. Native alternatives if you prefer Claude's own: `claude --tmux`, `claude --bg`.

**Guardrails:** every worktree is fully isolated, so parallel agents never collide. Nothing is
auto-pushed - always review each branch and run it through the gate before merging.

### Playbook 10 - Shipping through the gate (our no-mistakes alternative)

*`gate` validates committed work in a disposable worktree and only pushes + opens a PR once it
passes. Our self-owned version of no-mistakes - no external binary; built on `git-wt` + the coding
agent + `gh`.*

**One-time per repo:**

```bash
/init-gate        # (or: gate init) writes .gate.sh
```

`.gate.sh` (plain sourced bash, not YAML) sets:
`GATE_TEST`, `GATE_LINT` (enforced), `GATE_REVIEW_CMD` (advisory, e.g. `/review-diff`; empty to skip),
`GATE_FIX_CMD` (how auto-fixes are requested), `GATE_MAX_ROUNDS` (auto-fix attempts), `GATE_PUSH_REMOTE`.

**Ship a branch:**

```bash
# commit your work first - the gate validates commits, not the dirty tree
/ship-gate        # (or: gate run [branch])
```

Pipeline:

1. Copies the branch HEAD into a **disposable worktree** - your working tree is untouched.
2. **review** - *advisory*: surfaces findings, never blocks (an LLM's verdict isn't a reliable
   exit code, so review informs while tests/lint enforce).
3. **test** then **lint** - *enforced*, each with a bounded **auto-fix loop**: on failure it runs
   the `build` agent to fix, commits the fix, and re-runs, up to `GATE_MAX_ROUNDS`.
4. All green → fast-forward your local branch, push the validated commits, `gh pr create`.
5. Can't fix within the cap → **escalates**: nothing is pushed, and the disposable worktree is
   kept for you to inspect.

**How it fits with reviews:** the gate's review stage is a *quick advisory pass*. The deep,
human-in-the-loop review (Playbook 6 - `ceo-review`, `security-review`, `claude-review`,
`second-pass`) still happens **before** you run the gate. The gate then enforces the mechanical
bar (tests + lint) and opens the PR. **No yolo:** push/PR happen only after every enforced stage
passes, and the gate refuses to run on the default branch.

---

## Part 3 - Reference

### Commands (34) - OpenCode `/slash`, grouped by stage

Each routes to a subagent (which fixes the model) and usually uses the linked skill.

| Command | Agent (model) | Uses skill | Purpose |
|---|---|---|---|
| `/research` | researcher (gpt-5.5-fast) | research | Research a topic using live web sources |
| `/explain` | debugger (gpt-5.5) | explain | Explain code, behavior, or repo structure |
| `/investigate` | debugger (gpt-5.5) | investigate | Investigate a bug/failure before proposing fixes |
| `/autoplan` | architect (gpt-5.5) | autoplan | End-to-end implementation plan, no edits |
| `/plan-feature` | architect (gpt-5.5) | autoplan | Plan a feature implementation, no changes |
| `/architecture-check` | architect (gpt-5.5) | api-design, refactor-planner | Architecture review of a design/change |
| `/agentic-plan` | architect (gpt-5.5) | autoplan | Plan an agentic workflow (subagents, tools, orchestration) |
| `/refactor-plan` | refactor-planner (gpt-5.5) | refactor-planner | Safe refactor plan with sequencing + verification |
| `/plan-ceo-review` | critic (gpt-5.5) | ceo-review | Founder-lens review of a **plan** |
| `/plan-design-review` | architect (gpt-5.5) | design-review | Plan-stage UX/design-system/a11y review |
| `/plan-eng-review` | architect (gpt-5.5) | eng-review | Plan-stage architecture/edge-case/test review |
| `/review-diff` | reviewer (gpt-5.5) | code-review | Review unstaged+staged diffs for bugs/regressions |
| `/review-staged` | reviewer (gpt-5.5) | code-review | Review only staged changes pre-commit |
| `/long-context-review` | reviewer (gpt-5.5) | code-review | Review across many files / a long diff |
| `/ui-review` | reviewer (gpt-5.5) | frontend-design | Visual/UI review of implemented components |
| `/ship-check` | reviewer (gpt-5.5) | - | Final readiness review before merge/release |
| `/security-review` | security-reviewer (gpt-5.5) | security-review | Security review of changes + nearby risky code |
| `/ceo-review` | critic (gpt-5.5) | ceo-review | Founder-lens review of a **change/diff** |
| `/second-opinion` | critic (gpt-5.5) | critique | Independent second opinion on a plan/diff/review |
| `/critique` | critic (gpt-5.5) | critique | Critique of recent analysis/review |
| `/claude-review` | reviewer → `claude` CLI | - | Second opinion from the Claude CLI (your Claude sub) |
| `/second-pass` | reviewer (gpt-5.5) | second-pass | Re-review after fixes; confirm resolved, no regressions |
| `/test-plan` | tester (gpt-5.5) | test-writer | Practical test plan for a change/feature |
| `/qa-only` | tester (gpt-5.5) | - | Test changed behavior, report bugs, no code changes |
| `/debug-tests` | debugger (gpt-5.5) | debugging | Debug failing tests, root-cause first |
| `/ship-gate` | build → `gate` | ship-gate | Validate in a disposable worktree, then push + PR |
| `/commit` | pr-writer (gpt-5.4-mini) | git-commit | Commit staged changes (this repo or child repos) |
| `/commit-message` | pr-writer (gpt-5.4-mini) | git-commit | Draft a commit message (never commits) |
| `/branch-name` | pr-writer (gpt-5.4-mini) | - | Suggest short branch names from worktree context |
| `/changelog` | pr-writer (gpt-5.4-mini) | release-notes | Draft changelog/release notes from commits+diffs |
| `/pr-body` | pr-writer (gpt-5.4-mini) | pull-request | Draft a PR title + body from branch changes |
| `/docs-update` | docs-writer (gpt-5.4-mini) | documentation | Update docs/README from current changes |
| `/init-agents-md` | build (gpt-5.5) | init-agents-md | Seed a per-project `AGENTS.md` (+ `CLAUDE.md` symlink) |
| `/init-gate` | build (gpt-5.5) | - | Seed a `.gate.sh` ship-gate config |

### Skills (28) - shared across Claude, Codex, OpenCode

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
| `ship-gate` | Drive the `gate` CLI + `.gate.sh` | `/ship-gate` |
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
| `architect` | gpt-5.5 | Architecture / plan reviews | no |
| `debugger` | gpt-5.5 | Investigate bugs / failing tests | limited |
| `tester` | gpt-5.5 | Test plans / QA, no code changes | no |
| `reviewer` | gpt-5.5 | Code/UI/ship review, findings-first | no (deny) |
| `security-reviewer` | gpt-5.5 | Security review | no |
| `docs-writer` | gpt-5.4-mini | Docs / README | docs only |
| `pr-writer` | gpt-5.4-mini | Commits, PR bodies, changelogs | commit-scope |
| `refactor-planner` | gpt-5.5 | Refactor planning | no |
| `researcher` | gpt-5.5-fast | Live web research | no |
| `critic` | gpt-5.5 | Founder/critique/second-opinion | no |

OpenCode built-ins `build` and `plan` still live in `opencode.json`.
Generated Claude/Codex roles cover the 10 custom subagents above.

### Scripts (`scripts/.local/bin`, on `$PATH`)

| Tool | Subcommands | Purpose |
|---|---|---|
| `git wt` / `wt` | `new`, `ls`, `path`, `rm`, `prune` | Sibling worktrees; `wt` adds `cd`; `.worktrees-setup` post-create hook |
| `crew` | `new`, `ls`, `attach`, `stop` | tmux multi-agent orchestrator over `wt`; supports `--claude` and `--codex` |
| `gate` | `init`, `run`, `status` | Ship gate: disposable-worktree validate → push → PR; `init --engine opencode|claude|codex` |
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
| `.gate.sh` (per repo) | `gate` | Test/lint/review commands + auto-fix rounds for the ship gate |
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
