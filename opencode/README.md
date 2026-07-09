# OpenCode Dotfiles Package

> 📖 **New here?** Read [`docs/WORKFLOW.md`](../docs/WORKFLOW.md) for the end-to-end agentic
> workflow - playbooks (plan a product/feature, fix a bug, parallel agents, ship gate) plus a
> full reference for every command, skill, subagent, and config file.

This package is a GNU Stow package for global OpenCode config.

It installs:

- Global OpenCode config at `~/.config/opencode/opencode.json`.
- Global subagents in `~/.config/opencode/agents/`.
- Global commands in `~/.config/opencode/commands/`.
- Noctalia TUI theme in `~/.config/opencode/themes/noctalia.json`.
- TUI config at `~/.config/opencode/tui.json`.

> **Skills live in the `agents/` package, not here.** `~/.config/opencode/skills/` is the
> canonical skills dir, owned by the `agents/` stow package and shared (symlinked) with
> Claude and Codex. See `agents/README.md`. This package owns everything else under
> `~/.config/opencode/` except `skills/` and `AGENTS.md`.

The setup is intentionally stack-neutral. Laravel, Filament, Livewire, product-domain, and company-specific instructions should stay in each repo under `.opencode/`.

## Config Locations

OpenCode reads global user config from:

```text
~/.config/opencode/opencode.json
~/.config/opencode/tui.json
~/.config/opencode/agents/
~/.config/opencode/commands/
~/.config/opencode/skills/
~/.config/opencode/plugins/
```

This dotfiles package manages only `~/.config/opencode` content.

`~/.opencode` is **not** managed by this package. It is plugin/runtime/auth state (OAuth accounts, locks, backups, caches, generated `node_modules`). The package's `.stow-local-ignore` excludes `.opencode` and `node_modules` so anything OpenCode or its plugins write there will never end up under stow control.

## Dependencies

Install these first:

```bash
# Arch Linux
sudo pacman -S stow bun git

# macOS
brew install stow oven-sh/bun/bun git
```

You also need OpenCode installed and available as `opencode`.

```bash
opencode --version
```

OpenCode installs npm plugins automatically with Bun at startup and caches them under `~/.cache/opencode/node_modules/`. Some plugins may also create runtime state under `~/.opencode`; keep that directory out of dotfiles.

## Install With Stow

From the dotfiles repo root, dry-run first:

```bash
stow --no-folding -t "$HOME" -nv opencode
```

If the dry run looks correct:

```bash
stow --no-folding -t "$HOME" -v opencode
```

If a plugin or installer (e.g. `npx oc-codex-multi-auth@latest`) overwrites the stowed config files, restow to recreate the symlinks:

```bash
stow --no-folding -R -t "$HOME" -v opencode
```

`stow -R` will replace the real files the installer wrote with symlinks pointing back into this repo.

If you already have a real `~/.config/opencode` directory, back it up first:

```bash
mv ~/.config/opencode ~/.config/opencode.backup.$(date +%Y%m%d-%H%M%S)
mkdir -p ~/.config/opencode
stow --no-folding -t "$HOME" -v opencode
```

`--no-folding` is intentional. It prevents Stow from turning the entire `~/.config/opencode` directory into one symlink, so OpenCode can safely create runtime files such as plugin caches, locks, and local state without writing them into this repo.

### Stow ignore rules

`opencode/.stow-local-ignore` keeps the following out of the link set so plugin and runtime state is never adopted into the package:

```text
README.md
\.opencode
node_modules
```

If you want to restore non-secret local files from the backup, copy them back explicitly after stowing. For example:

```bash
cp ~/.config/opencode.backup.<timestamp>/tui.json ~/.config/opencode/tui.json
cp -r ~/.config/opencode.backup.<timestamp>/themes ~/.config/opencode/themes
```

Do not copy back generated or secret state:

```text
node_modules/
cache/
*.lock
*auth*
*secret*
backups/
```

Restart OpenCode after linking:

```bash
opencode
```

## Model Routing

Model selection is **centralized in `opencode.json`** under the `agent` block. Commands only choose an agent; they do not choose models. Skills are prompt/tooling instructions and do not choose models.

Normal initial sessions use `default_agent: build` with `model: openai/gpt-5.5`.

To change routing on a new machine, edit `~/.config/opencode/opencode.json` only. Agent `.md`, command `.md`, and skill `SKILL.md` files should not contain `model:` frontmatter.

### Command Routing

| Commands                                                                              | Agent               |
| ------------------------------------------------------------------------------------- | ------------------- |
| `/review-diff`, `/review-staged`, `/ship-check`, `/ui-review`, `/long-context-review`, `/second-pass`, `/claude-review` | `reviewer`          |
| `/security-review`                                                                    | `security-reviewer` |
| `/plan-feature`, `/architecture-check`, `/agentic-plan`, `/autoplan`, `/plan-design-review`, `/plan-eng-review` | `architect`         |
| `/plan-ceo-review`, `/ceo-review`, `/second-opinion`, `/critique`, `/proposal-review`, `/proposal-commercial-review` | `critic`            |
| `/ship-gate`, `/init-gate`, `/init-agents-md`                                          | `build`             |
| `/debug-tests`, `/investigate`, `/explain`                                             | `debugger`          |
| `/test-plan`                                                                          | `tester`            |
| `/qa-only`                                                                            | `tester`            |
| `/refactor-plan`                                                                      | `refactor-planner`  |
| `/commit`, `/commit-message`, `/branch-name`, `/changelog`, `/pr-body`                | `pr-writer`         |
| `/docs-update`, `/proposal-draft`, `/proposal-prototype`                              | `docs-writer`       |

Model fallback or escalation is handled by editing the relevant agent model in `opencode.json`, not by keeping duplicate model-specific commands.

`/commit` creates commits from currently staged changes. It does not stage files automatically; stage what you want included first, then run `/commit`. If you run it from a folder that is not itself a git repo, it discovers child repos/submodules and commits each one with staged changes. If the current folder is also a repo, it includes that repo too.

`/commit` uses a Conventional Commit subject plus a short body by default, so later `git log` readers can see both what changed and why. It omits the body only for truly trivial changes.

`/commit-message` only drafts the message and never runs `git commit`. It uses the same subject/body format as `/commit`.

## Workflow

A lightweight OpenCode-native sprint shape (loosely inspired by gstack's, but fully
self-contained - nothing from gstack is installed or required):

```text
Think → Plan → Build → Review → Test → Ship → Reflect
```

Recommended command flow:

| Stage   | OpenCode command                                             | Notes                                      |
| ------- | ------------------------------------------------------------ | ------------------------------------------ |
| Think   | `/research`, `/explain`, or normal chat                      | Clarify unknowns before planning.          |
| Plan    | `/autoplan`, `/plan-feature`, `/architecture-check`          | Save scope, risks, files, and tests.       |
| Plan review | `/plan-ceo-review`, `/plan-design-review`, `/plan-eng-review` | Founder / designer / eng-lens critique before building. |
| Build   | Normal `build` agent                                         | Keep changes small and repo-patterned.     |
| Review  | `/review-diff`, `/ui-review`, `/security-review`, `/ceo-review`, `/claude-review`, `/second-pass` | Findings first; `/claude-review` = Claude-CLI second opinion; `/second-pass` re-checks after fixes. |
| Test    | `/qa-only`, `/test-plan`, `/debug-tests`, project tests      | Reproduce failures before fixing.          |
| Ship    | `/ship-check`, `/ship-gate`, `/docs-update`, `/changelog`, `/pr-body` | `/ship-gate` = disposable-worktree validate → push → PR. |
| Commit  | `/commit-message`, `/commit`, `/branch-name`                 | Descriptive commit bodies by default.      |

### Verifying / changing models

List configured default and agent models:

```bash
jq '{model, default_agent}' ~/.config/opencode/opencode.json
jq '.agent' ~/.config/opencode/opencode.json
```

Verify commands, agents, and skills do not override models:

```bash
grep -hRE '^model:' ~/.config/opencode/commands ~/.config/opencode/agents ~/.config/opencode/skills 2>/dev/null
```

## Shared cross-agent AGENTS.md

Global behavioral instructions are shared across Claude Code, Codex, and OpenCode via a
separate **`agents/`** stow package (see `agents/README.md`). One canonical
`~/AGENTS.md` is symlinked into each agent:

```text
~/AGENTS.md                          (canonical, short - loads into every agent's context)
~/.claude/CLAUDE.md          -> ~/AGENTS.md
~/.codex/AGENTS.md           -> ~/AGENTS.md
~/.config/opencode/AGENTS.md -> ~/AGENTS.md   (owned by the agents package, not this one)
```

This `opencode/` package still owns everything else under `~/.config/opencode/`
(`opencode.json`, `tui.json`, `agents/`, `commands/`, `skills/`, `themes/`); it only
does **not** own `AGENTS.md`, so there is no stow conflict.

Per-project instructions stay in each repo's own `AGENTS.md` - seed one with
`/init-agents-md`.

## Review roles

Lightweight review commands borrow the CEO / design / eng lenses without vendoring gstack:

- **CEO / founder** - `/plan-ceo-review` (plan) and `/ceo-review` (diff): framing, scope, value.
- **Design** - `/plan-design-review` (plan). For implemented UI use the existing `/ui-review`.
- **Engineering** - `/plan-eng-review` (plan). For an implemented change use `/architecture-check`.
- **Second opinions** - `/second-opinion` (critic) and `/claude-review` (hands the
  diff to the `claude` CLI using your Claude subscription - no Anthropic provider is configured
  in OpenCode).
- **Re-review** - `/second-pass`: confirms prior findings are resolved and no regressions crept in.

To avoid command sprawl, these reuse the existing `critic` / `architect` / `reviewer` agents;
no new models were added.

## Headless browser skill

The `browser` skill (`skills/browser/`) gives OpenCode a **headless, CLI-driven** browser
(`browser-cli.ts`, Bun) for web QA and scraping - fetch text, screenshot, click, fill,
assert, and axe-core a11y scans.
If Playwright's Chromium is not installed, `text` degrades to a plain fetch; other ops print
`bunx playwright install chromium`.

## Worktrees and the crew orchestrator

Parallel agent work uses our own tools (in the `scripts` package, on `$PATH`):

- **`git wt`** / **`wt`** - sibling git worktrees, one isolated checkout per branch/agent.
  An optional executable `.worktrees-setup` at the repo root runs after each `git wt new`
  (copy `.env`, install deps).
- **`crew`** - a lightweight tmux orchestrator (our own take on firstmate, no external scripts):
  `crew new "<task…>"` spins up a worktree + detached tmux session running an agent, with the
  branch AI-named from the task (pass `-b <name>` to force/reuse one);
  `crew ls` / `crew attach <branch>` / `crew stop <branch> [-D]` manage the fleet.

## Ship gate

`/ship-gate` runs our own **`gate`** CLI (in the `scripts` package): it validates a branch's
committed work in a **disposable worktree** (advisory review → test → docs → lint) and only
pushes + opens a PR once the gate passes.
If `.gate.sh` does not set test/lint commands, the build agent detects and runs relevant checks.
On an unfixable failure it escalates and pushes nothing.
No external binary.
Use `/init-gate` only when you want optional `.gate.sh` deterministic overrides.
See `skills/ship-gate/SKILL.md`.

## Token efficiency

Guardrails are baked into `~/AGENTS.md` and the review commands:

- Shortest useful answer first; don't re-read files already in context.
- Reviews: findings first, severity-tagged, one line of context each - don't summarize a diff.
- Prefer targeted `grep`/read over broad `find`/`cat`.
- Routing is OpenAI-only by default (`small_model` = `openai/gpt-5.4-nano`);
  edit `opencode.json` if you want to change agent-specific model choices.

## Plugins

No **npm** plugins are declared. The previous `oc-codex-multi-auth` plugin was removed because it caused issues (overwriting stowed config files, among others).

One **local** TUI plugin is vendored in this package:

```text
codex-status.ts            shows ChatGPT/Codex usage + rate-limit % in the TUI bottom-right
```

It is declared in `tui.json` (not `opencode.json`) as a relative path:

```jsonc
// ~/.config/opencode/tui.json
{ "plugin": ["./codex-status.ts"] }
```

The `./` resolves relative to `~/.config/opencode/`, so the file must live at
`~/.config/opencode/codex-status.ts` (stow links it there from
`opencode/.config/opencode/codex-status.ts`). It renders a compact string such as
`5h 72% · 1d 41%`. It reads OpenCode's own OAuth store
(`~/.local/share/opencode/auth.json`, key `codex`), falling back to the Codex CLI
(`~/.codex/auth.json`); **no auth or secrets are stored in this repo**. Requires `bun`.

A standalone companion CLI lives in the separate **`scripts`** stow package and prints the
same usage on demand from the terminal:

```bash
codex-status            # one-shot summary
codex-status --json     # raw payload as JSON
codex-status --watch 30 # refresh every N seconds (default 30) until Ctrl-C
```

It is `scripts/.local/bin/codex-status` in the repo and installs to `~/.local/bin/codex-status`
via `stow --no-folding -t "$HOME" -v scripts`. It also requires `bun` (it runs under
`#!/usr/bin/env bun`).

If you add npm plugins later, declare them under the `"plugin"` key in `~/.config/opencode/opencode.json`. OpenCode loads npm plugins on startup with Bun and caches them under `~/.cache/opencode/packages/` and `~/.opencode/node_modules/` - both paths are intentionally excluded from this stow package.

Avoid one-shot installers (`npx some-plugin@latest`) that rewrite the config files in `~/.config/opencode/`. They overwrite the stowed symlinks with real files. If one runs anyway, restow:

```bash
stow --no-folding -R -t "$HOME" -v opencode
```

## New Machine Setup

From a fresh machine:

```bash
git clone <private-dotfiles-repo> ~/dev/github.com/mshiyaf/dotfiles
cd ~/dev/github.com/mshiyaf/dotfiles
mkdir -p ~/.config/opencode
stow --no-folding -t "$HOME" -v opencode
opencode
```

If `opencode.json` declares any plugins, OpenCode will install them on startup. Authenticate any providers with:

```bash
opencode auth login
```

OAuth/auth state is created per machine and is not synced through Git.

## Skills

> Skills are owned by the **`agents/`** stow package (`agents/.config/opencode/skills/`) and
> shared across OpenCode, Claude, and Codex via symlinks - the same `SKILL.md` set for all
> three. See `agents/README.md`. The list below documents the shared set; it is not
> installed by this `opencode/` package.

This set vendors a small reviewed subset of public skills and keeps concise local fallback skills for day-to-day work.

Vendored public skills:

```text
find-skills                from vercel-labs/skills
systematic-debugging       from obra/superpowers
test-driven-development    from obra/superpowers
```

These are trimmed copies, not a live install from npm or `skills add`. They are stored in `agents/.config/opencode/skills/` so Stow can manage them deterministically.

Local fallback skills:

```text
git-commit                 Conventional Commits by default
code-review                findings-first review checklist
security-review            concise global security checklist
debugging                  lightweight alias that can escalate to systematic-debugging
test-writer                lightweight alias that can escalate to test-driven-development
documentation              docs and README procedure
api-design                 generic API review checklist
database-review            generic schema/query/migration checklist
refactor-planner           safe refactor planning checklist
frontend-design            concise frontend design checklist
release-notes              changelog and release note procedure
pull-request               PR title/body/test-plan procedure
```

The fallback skills exist because public options for commits, PR bodies, changelogs, API, database, and security review were either too broad, too narrow, or less predictable for global use.

## Optional External Public Skills

If you want to install public skills later, prefer a small curated set and review each `SKILL.md` before installing:

```bash
npx skills add https://github.com/vercel-labs/skills --skill find-skills
npx skills add https://github.com/obra/superpowers --skill systematic-debugging
npx skills add https://github.com/obra/superpowers --skill test-driven-development
npx skills add https://github.com/obra/superpowers --skill requesting-code-review
npx skills add https://github.com/obra/superpowers --skill finishing-a-development-branch
npx skills add https://github.com/anthropics/skills --skill frontend-design
```

Do not re-install the three vendored skills globally unless you intentionally want to replace the trimmed versions with upstream copies. If you do, compare the content first because upstream skills may be longer or more opinionated.

Do not install large random skill packs globally. Put project-specific skills in the project repo under `.opencode/skills/<name>/SKILL.md`.

## Commands

After restart, type `/` in OpenCode and check for:

Primary commands:

```text
/commit              /commit-message      /branch-name
/changelog           /pr-body             /docs-update
/explain             /debug-tests         /test-plan
/plan-feature        /refactor-plan       /review-diff
/review-staged       /security-review     /ship-check
/second-opinion      /architecture-check  /long-context-review
/ui-review           /agentic-plan        /critique
```

Review + workflow additions:

```text
/plan-ceo-review     /ceo-review          /plan-design-review
/plan-eng-review     /second-pass         /claude-review
/ship-gate           /init-gate           /init-agents-md
```

Model-specific fallback commands are intentionally not installed. Change agent model routing in `opencode.json` when you want a different model.

## Agents

Global subagents:

```text
@reviewer
@security-reviewer
@tester
@docs-writer
@architect
@debugger
@pr-writer
@refactor-planner
@critic
@researcher
```

## Verification

```bash
find ~/.config/opencode/agents -maxdepth 1 -type f -name '*.md' | sort
find ~/.config/opencode/commands -maxdepth 1 -type f -name '*.md' | sort
find ~/.config/opencode/skills -maxdepth 2 -name SKILL.md | sort
find ~/.config/opencode/themes -maxdepth 1 -type f -name '*.json' | sort
test -L ~/.config/opencode/opencode.json && readlink ~/.config/opencode/opencode.json
test -L ~/.config/opencode/tui.json && readlink ~/.config/opencode/tui.json
```

Check that OpenCode is not unexpectedly seeing old Claude/agent skills:

```bash
find ~/.claude/skills ~/.agents/skills -maxdepth 2 -name SKILL.md 2>/dev/null
```

Check for accidental global project-specific skills:

```bash
grep -RniE 'laravel|filament|livewire|zivents|matchmaking|tenant|company|domain' ~/.config/opencode/skills ~/.config/opencode/agents ~/.config/opencode/commands 2>/dev/null
```

The `opencode.json` permission block denies common project-specific skill name patterns globally, but OpenCode still discovers `~/.claude/skills` and `~/.agents/skills`. Move unwanted skills out of those paths if they should not be visible.

## Uninstall

From the dotfiles repo root:

```bash
stow --no-folding -t "$HOME" -Dv opencode
```

This removes the symlinks only. It does not delete backups or OpenCode cache files.
