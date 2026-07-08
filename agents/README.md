# Agents Dotfiles Package

> 📖 See [`docs/WORKFLOW.md`](../docs/WORKFLOW.md) for the full agentic workflow (playbooks +
> command/skill/config reference).

GNU Stow package for the **shared, cross-agent layer**: the global instruction file
**and** the skills/subagent definitions, symlinked into every AI agent's config so Claude Code, Codex, and
OpenCode all read the same instructions and portable `SKILL.md` set.

## Shared instructions

One canonical file - `agents/AGENTS.md` - symlinked into each host:

```text
agents/AGENTS.md                       <- the real file
  ~/AGENTS.md                          (stowed real file)
  ~/.claude/CLAUDE.md   -> ~/AGENTS.md (Claude Code)
  ~/.codex/AGENTS.md    -> ~/AGENTS.md (Codex)
  ~/.config/opencode/AGENTS.md -> ~/AGENTS.md (OpenCode)
```

## Shared Skills

Skills use the one format all three tools agree on (`SKILL.md` = `name` + `description` +
markdown). The canonical set lives at `agents/.config/opencode/skills/`; Claude and Codex
symlink their whole skills dir to it:

```text
agents/.config/opencode/skills/        <- canonical SKILL.md set (real files)
  ~/.config/opencode/skills/           (OpenCode - real dir of per-file symlinks)
  ~/.claude/skills  -> ~/.config/opencode/skills  (Claude Code)
  ~/.codex/skills   -> ~/.config/opencode/skills  (Codex)
```

New command-backed skills: `autoplan`, `investigate`, `research`, `critique`, `explain`, and `init-agents-md`.
These replace tool-specific command trees for Claude/Codex.
OpenCode keeps thin slash-command wrappers where model routing is useful.

> Note: OpenCode also discovers `~/.claude/skills`, which now resolves to the same set. If
> its skill picker shows duplicates, drop one discovery path - but skills key by name, so
> it usually dedupes.

## Generated Subagents

OpenCode remains the canonical source for role prompts:

```text
opencode/.config/opencode/agents/*.md      <- canonical prompts and descriptions
agents/models.json                         <- role -> model map
agents/.claude/agents/*.md                 <- generated Claude Code subagents
agents/.codex/agents/*.toml                <- generated Codex subagents
```

Run `make agents-sync` after editing an OpenCode agent or `agents/models.json`.
Run `agents-sync --check` in verification to fail if generated files are stale.

Read-only roles (`reviewer`, `security-reviewer`, `critic`, `architect`, `refactor-planner`, `researcher`) get Claude `Read, Grep, Glob, Bash` tools and Codex `sandbox_mode = "read-only"`.
Edit-capable roles (`debugger`, `tester`, `docs-writer`, `pr-writer`) also get Claude `Edit, Write` and Codex `sandbox_mode = "workspace-write"`.

`agents/models.json` is listed in `.stow-local-ignore`, so it stays repo-local and never stows into `$HOME`.

## Claude Code Config

This package owns `~/.claude/settings.json`.
It merges the live settings with permission parity and the statusline command:

- allow `git status`, `git diff`, `git log`, and common test runners without prompting
- deny `git push`
- run `~/.local/bin/claude-statusline` for the status line

Write-through the symlink is desired dotfiles behavior: Claude `/config` edits should land in this repo and show in `git diff`.
If Claude Code ever writes via atomic rename, it may replace the symlink with a real file.
After a `/config` change, check `test -L ~/.claude/settings.json`.
If it is no longer a symlink, diff the real file, merge wanted changes into `agents/.claude/settings.json`, remove the real file, and run `make restow-agents`.

## Codex Config

Do not symlink `~/.codex/config.toml`.
It contains machine-local churn such as project trust levels and NUX state.

Hand-merge this stable posture into `~/.codex/config.toml`:

```toml
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

The package includes `agents/.codex/rules/default.rules` using Codex `prefix_rule()` syntax.
It allows git status/diff/log and common test runners, forbids `git push`, and leaves everything else to the approval policy.
Keep `~/.codex/skills` as the only repo-managed Codex skills symlink.
Do not stow `~/.agents/skills`; that path is intentionally left as a real directory for third-party skills.

## Install / update

Stow refuses to overwrite real files/dirs, so clear conflicting paths first:

```bash
# 1. Back up an existing real global CLAUDE.md (e.g. from another tool)
[ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ] && \
  mv "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.bak"

# 2. Remove empty host skills dirs so they can become symlinks (back up if non-empty)
rmdir "$HOME/.claude/skills" "$HOME/.codex/skills" 2>/dev/null || true

# 3. Back up a real Claude settings file before stowing this package
[ -e "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ] && \
  mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.pre-stow.bak"

make agents-sync
make stow-agents        # or: make restow-agents
```

`~/AGENTS.md` and `~/.codex/AGENTS.md` do not usually exist yet, so they stow cleanly.

## Verify

```bash
readlink -f ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.config/opencode/AGENTS.md   # -> agents/AGENTS.md
readlink -f ~/.claude/skills ~/.codex/skills                                       # -> the shared skills dir
readlink -f ~/.claude/settings.json ~/.claude/agents/reviewer.md ~/.codex/agents/reviewer.toml
agents-sync --check
ls ~/.claude/skills ~/.config/opencode/skills | sort -u | head                     # same skill set
```

## Notes

- The OpenCode `opencode/` package owns `~/.config/opencode/opencode.json`, `tui.json`,
  `agents/`, `commands/`, `themes/`. This package owns `~/.config/opencode/AGENTS.md` and
  `~/.config/opencode/skills/`, so there is no stow conflict.
- Keep `AGENTS.md` short - it loads into every agent's context on every session.
