---
name: autoplan
description: Use when creating end-to-end implementation plans, feature plans, or agentic workflow plans before editing code.
---

# Autoplan

Use this skill to produce an implementation plan without editing files.

Gather context first when available:

- Run `git status --short`.
- Run `git branch --show-current`.
- Run `git log --oneline -10`.
- Inspect nearby repo orientation files such as `README*`, `AGENTS.md`, `CLAUDE.md`, `package.json`, `composer.json`, `go.mod`, and `Cargo.toml`.

Use `api-design`, `code-review`, `test-writer`, `security-review`, `database-review`, and `refactor-planner` skills when relevant.

Create an implementation plan following a Think -> Plan -> Build -> Review -> Test -> Ship flow.

Include:

- Problem framing and assumptions to verify
- Scope and non-goals
- Likely files and ownership boundaries
- Data/API/config/security impact
- Subagents, tools, prompts, and orchestration when planning an agentic workflow
- Step-by-step implementation sequence
- Test and verification plan
- Review gates before commit or ship
- Rollback or recovery notes when relevant

Do not edit files.
If the request is too ambiguous, ask only the smallest blocking questions.
