# Agents Dotfiles Package

> 📖 See [`docs/WORKFLOW.md`](../docs/WORKFLOW.md) for the full agentic workflow (playbooks +
> command/skill/config reference).

GNU Stow package for the **shared, cross-agent layer**: the global instruction file
**and** the skills/subagent definitions, symlinked into every AI agent's config so Claude Code,
Codex, OpenCode, Kimi Code, and Amp all read the same instructions and portable `SKILL.md` set.

## Shared instructions

One canonical file - `agents/AGENTS.md` - symlinked into each host:

```text
agents/AGENTS.md                       <- the real file
  ~/AGENTS.md                          (stowed real file)
  ~/.claude/CLAUDE.md   -> ~/AGENTS.md (Claude Code)
  ~/.codex/AGENTS.md    -> ~/AGENTS.md (Codex)
  ~/.config/opencode/AGENTS.md -> ~/AGENTS.md (OpenCode)
  ~/.kimi-code/AGENTS.md -> ~/AGENTS.md (Kimi Code)
  Amp reads ~/AGENTS.md directly
```

## Shared Skills

Skills use the portable format all five tools support (`SKILL.md` = `name` + `description` +
markdown). The canonical set lives at `agents/.config/opencode/skills/`; Claude and Codex
and Kimi Code symlink their whole skills dir to it, while Amp discovers the Claude path:

```text
agents/.config/opencode/skills/        <- canonical SKILL.md set (real files)
  ~/.config/opencode/skills/           (OpenCode - real dir of per-file symlinks)
  ~/.claude/skills  -> ~/.config/opencode/skills  (Claude Code)
  ~/.codex/skills   -> ~/.config/opencode/skills  (Codex)
  ~/.kimi-code/skills -> ~/.config/opencode/skills (Kimi Code)
  Amp discovers ~/.claude/skills
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

Kimi Code does not currently document an equivalent format for independently model-pinned custom
role agents.
It uses the shared skills and the native `coder`, `explore`, and `plan` subagents instead;
workflows that require explicit K2.7 or K3 routing launch that model through `crew` or `gate`.

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
The `codex/` directory is ignored, so it is never a Stow package.

`agents/codex-config.toml.example` is the portable baseline and is ignored by this package's `.stow-local-ignore`.
On each machine, create the real `~/.codex/config.toml` from it if no configuration exists:

```bash
mkdir -p "$HOME/.codex"
[ -e "$HOME/.codex/config.toml" ] || \
  cp agents/codex-config.toml.example "$HOME/.codex/config.toml"
```

If the file already exists, merge the template's settings manually instead of overwriting it.
Do not copy `[projects."..."]` `trust_level` entries, TUI NUX state, credentials, or absolute machine-specific command paths.
Codex recreates trust entries when you explicitly trust each project.

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

# 2. Claude can use the shared skills symlink. Keep Codex skills as a real
# directory so Codex owns .system and Stow links only the shared user skills.
rmdir "$HOME/.claude/skills" 2>/dev/null || true
mkdir -p "$HOME/.codex/skills"

# 3. Back up a real Claude settings file before stowing this package
[ -e "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ] && \
  mv "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.pre-stow.bak"

# New machine: install the active package set.
make agents-sync && make stow

# Existing machine after pulling changes: refresh the active package set.
make agents-sync && make restow
```

`make stow` creates missing links.
`make restow` refreshes links that are already managed by the selected packages and creates newly added links.
Both use the same default package set: `agents`, `alacritty`, `fastfetch`, `git`, `herdr`, `kitty`, `niri`, `noctalia`, `nvim`, `opencode`, `scripts`, `tmux`, `zprofile`, `zsh`, and `zshenv`.
Use `make restow-agents`, `make restow-opencode`, or `make restow-scripts` only when updating that package alone.

Codex installs its bundled skills as real files under `~/.codex/skills/.system`.
The Stow package ignores that host-owned path when `~/.codex/skills` already exists, while continuing to manage the other shared skills.
If `~/.codex/skills` is already a symlink from an older setup, preserve `.system`, replace that symlink with a real directory, restore `.system`, and then restow.

`~/AGENTS.md` and `~/.codex/AGENTS.md` do not usually exist yet, so they stow cleanly.

## Verify

```bash
readlink -f ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.config/opencode/AGENTS.md ~/.kimi-code/AGENTS.md   # -> agents/AGENTS.md
readlink -f ~/.claude/skills ~/.codex/skills ~/.kimi-code/skills                                       # -> the shared skills dir
readlink -f ~/.claude/settings.json ~/.claude/agents/reviewer.md ~/.codex/agents/reviewer.toml
agents-sync --check
ls ~/.claude/skills ~/.config/opencode/skills | sort -u | head                     # same skill set
```

## Notes

- The OpenCode `opencode/` package owns `~/.config/opencode/opencode.json`, `tui.json`,
  `agents/`, `commands/`, `themes/`. This package owns `~/.config/opencode/AGENTS.md` and
  `~/.config/opencode/skills/`, so there is no stow conflict.
- Keep `AGENTS.md` short - it loads into every agent's context on every session.
