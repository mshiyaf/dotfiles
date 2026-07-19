# Amp-specific workflow

The shared rules in `~/AGENTS.md` still apply.

- Herdr is the primary local multiplexer; tmux is the fallback.
- Use native Amp subagents for independent research, read-only review, and high-output work.
- Use `crew` for concurrent edits that need isolated local worktrees or another agent harness.
- Orb threads start from a fresh clone and cannot see uncommitted local state.
  Use a live runner or a Crew worktree when a task depends on local state.
- Use Finder for behavior-level local discovery, Librarian for external repository internals, and Oracle for difficult judgment or review.
- Keep MCP servers opt-in and skill-scoped; prefer built-in tools or a CLI when they are sufficient.
