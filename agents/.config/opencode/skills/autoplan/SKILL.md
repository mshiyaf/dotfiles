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

Create an implementation plan following a Think -> Align -> Plan -> Build -> Review -> Test -> Ship flow.

Separate what is known from what still requires judgment:

- **Facts:** verified from repository or authoritative evidence.
- **Decisions:** choices already made, including rationale when known.
- **Assumptions:** unverified defaults, each with confidence and consequence if wrong.
- **Open decisions:** only choices that materially affect scope, behavior, architecture, safety, or cost.

Investigate factual unknowns instead of asking the user.
If the user explicitly requests thorough requirements discovery, use `grill-me` before finalizing the plan.
Otherwise ask only questions whose answers would materially change the plan and provide a recommended default.

Include:

- Problem framing and verified facts
- Decisions made, open decisions, and assumptions to verify
- Scope and non-goals
- Observable acceptance criteria
- Likely files and ownership boundaries
- Data/API/config/security impact
- Recommended test seams, preferring existing public interfaces and focused contract boundaries
- Subagents, tools, prompts, and orchestration when planning an agentic workflow
- Dependency-ordered vertical slices, each behaviorally complete and independently verifiable
- Step-by-step implementation sequence, with blockers and work that must not run in parallel
- Test and verification plan
- Review gates before commit or ship
- Rollback or recovery notes when relevant

Each vertical slice should fit one fresh implementation context when practical and state its desired behavior, acceptance criteria, verification, dependencies, and non-goals.
Do not invent precise implementation tickets for work blocked by unresolved decisions.

Do not edit files.
If the request is too ambiguous, ask only the smallest blocking questions.
