# OpenCode Dotfiles Package

This package is a GNU Stow package for global OpenCode config.

It installs:

- Global OpenCode config at `~/.config/opencode/opencode.json`.
- Global subagents in `~/.config/opencode/agents/`.
- Global commands in `~/.config/opencode/commands/`.
- Small reusable global skills in `~/.config/opencode/skills/`.
- Noctalia TUI theme in `~/.config/opencode/themes/noctalia.json`.
- TUI config at `~/.config/opencode/tui.json`.
- OpenCode plugins declared in `opencode.json`.
- A non-secret Codex plugin preference at `~/.opencode/openai-codex-auth-config.json`.

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

Do not stow `~/.opencode` wholesale. This package intentionally manages only one non-secret file there:

```text
~/.opencode/openai-codex-auth-config.json
```

Everything else in `~/.opencode` is plugin/runtime/auth state used by Codex multi-auth tooling. It can contain OAuth accounts, locks, backups, cache, and generated dependencies. Recreate that state on each machine by authenticating accounts after OpenCode starts.

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

From the dotfiles repo root:

```bash
stow --no-folding -t "$HOME" -nv opencode
```

If the dry run looks correct:

```bash
stow --no-folding -t "$HOME" -v opencode
```

If you already have a real `~/.config/opencode` directory, back it up first:

```bash
mv ~/.config/opencode ~/.config/opencode.backup.$(date +%Y%m%d-%H%M%S)
mkdir -p ~/.config/opencode
stow --no-folding -t "$HOME" -v opencode
```

`--no-folding` is intentional. It prevents Stow from turning the entire `~/.config/opencode` directory into one symlink, so OpenCode can safely create runtime files such as plugin caches, locks, and local state without writing them into this repo.

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
oc-codex-multi-auth-accounts.json
backups/
```

If `~/.opencode/openai-codex-auth-config.json` already exists, either move it aside or let Stow link the repo version after backing it up:

```bash
mv ~/.opencode/openai-codex-auth-config.json ~/.opencode/openai-codex-auth-config.json.backup.$(date +%Y%m%d-%H%M%S)
stow --no-folding -t "$HOME" -v opencode
```

Restart OpenCode after linking:

```bash
opencode
```

## Model Routing

Model selection is **centralized in `opencode.json`** under the `agent` block. Commands only choose an agent; they do not choose models. Skills are prompt/tooling instructions and do not choose models.

To change routing on a new machine, edit `~/.config/opencode/opencode.json` only. Agent `.md`, command `.md`, and skill `SKILL.md` files should not contain `model:` frontmatter.

### Command Routing

| Commands | Agent |
|----------|-------|
| `/review-diff`, `/review-staged`, `/ship-check`, `/ui-review`, `/long-context-review` | `reviewer` |
| `/security-review` | `security-reviewer` |
| `/plan-feature`, `/architecture-check`, `/agentic-plan`, `/second-opinion` | `architect` |
| `/debug-tests`, `/explain` | `debugger` |
| `/test-plan` | `tester` |
| `/refactor-plan` | `refactor-planner` |
| `/commit`, `/branch-name`, `/changelog`, `/pr-body` | `pr-writer` |
| `/docs-update` | `docs-writer` |

Model fallback or escalation is handled by editing the relevant agent model in `opencode.json`, not by keeping duplicate model-specific commands.

### Verifying / changing models

List configured agent models:

```bash
jq '.agent' ~/.config/opencode/opencode.json
```

Verify commands, agents, and skills do not override models:

```bash
grep -hRE '^model:' ~/.config/opencode/commands ~/.config/opencode/agents ~/.config/opencode/skills 2>/dev/null
```

## Plugins

`opencode.json` currently declares these npm plugins:

```json
"plugin": ["oc-codex-multi-auth"]
```

OpenCode loads npm plugins from `opencode.json` and installs them automatically with Bun on startup (cached under `~/.cache/opencode/packages/`). This means the plugin installation is part of the stowed OpenCode system; the authenticated account data is intentionally not part of the repo. You do **not** need to run `npx oc-codex-multi-auth@latest` manually — OpenCode handles installation when it starts.

Start OpenCode once after stowing so plugins install:

```bash
opencode
```

## Codex Multi-Auth Plugin

The `oc-codex-multi-auth` plugin adds helper commands/tools for managing multiple Codex OAuth accounts and rate limits. The plugin is enabled by `~/.config/opencode/opencode.json`; account data is created under runtime/auth state after login.

After OpenCode starts with the plugin enabled, add accounts:

```bash
opencode auth login
```

Repeat `opencode auth login` once per account you want available on the machine.

Run the beginner checklist:

```bash
codex-setup
```

Use the guided onboarding wizard:

```bash
codex-setup --wizard
```

Verify account health:

```bash
codex-health
```

List configured accounts:

```bash
codex-list
```

Show current limits:

```bash
codex-limits
```

Show the live dashboard:

```bash
codex-dashboard
```

If requests fail or accounts stop refreshing:

```bash
codex-doctor
codex-refresh
```

Useful account management commands:

```bash
codex-status
codex-switch
codex-label
codex-tag
codex-note
```

Never commit OAuth tokens, exported account JSON, diagnostics with sensitive data, or provider credentials. Treat `~/.opencode/oc-codex-multi-auth-accounts.json` and `~/.opencode/backups/` as sensitive runtime state.

## New Machine Setup

From a fresh machine:

```bash
git clone <private-dotfiles-repo> ~/dev/github.com/mshiyaf/dotfiles
cd ~/dev/github.com/mshiyaf/dotfiles
mkdir -p ~/.config/opencode
stow --no-folding -t "$HOME" -v opencode
opencode
```

OpenCode will install the declared plugins on startup. Then authenticate accounts:

```bash
opencode auth login
codex-setup
codex-health
codex-list
```

The account OAuth state must be created per machine. Do not sync it through Git.

The only managed home-level plugin preference is:

```json
{
  "perProjectAccounts": false
}
```

It is linked to `~/.opencode/openai-codex-auth-config.json` by Stow.

## Skills

This package vendors a small reviewed subset of public skills and keeps concise local fallback skills for day-to-day work.

Vendored public skills:

```text
find-skills                from vercel-labs/skills
systematic-debugging       from obra/superpowers
test-driven-development    from obra/superpowers
```

These are trimmed copies, not a live install from npm or `skills add`. They are stored in `opencode/.config/opencode/skills/` so Stow can manage them deterministically.

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
/commit              /branch-name         /changelog
/pr-body             /docs-update         /explain
/debug-tests         /test-plan           /plan-feature
/refactor-plan       /review-diff         /review-staged
/security-review     /ship-check          /second-opinion
/architecture-check  /long-context-review /ui-review
/agentic-plan
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
```

## Verification

```bash
find ~/.config/opencode/agents -maxdepth 1 -type f -name '*.md' | sort
find ~/.config/opencode/commands -maxdepth 1 -type f -name '*.md' | sort
find ~/.config/opencode/skills -maxdepth 2 -name SKILL.md | sort
find ~/.config/opencode/themes -maxdepth 1 -type f -name '*.json' | sort
test -L ~/.opencode/openai-codex-auth-config.json && readlink ~/.opencode/openai-codex-auth-config.json
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
