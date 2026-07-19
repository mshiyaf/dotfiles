---
name: init-agents-md
description: Use when bootstrapping a project-level AGENTS.md and CLAUDE.md symlink for shared agent instructions.
---

# Init AGENTS.md

Create a project-level `AGENTS.md` if it does not already exist.
Do not commit.

Gather context first:

- Check for existing `AGENTS.md` and `CLAUDE.md`.
- Run `git rev-parse --show-toplevel` when inside git.
- Inspect nearby manifests such as `package.json`, `composer.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, and `Makefile`.

Steps:

1. If `AGENTS.md` already exists, stop and show its contents.
2. Do not overwrite an existing `AGENTS.md`.
3. Otherwise write a concise, under-50-line `AGENTS.md` inferred from the repo.
4. Include project name and one-line purpose.
5. Include stack and key frameworks.
6. Include build, test, and lint commands from the manifests.
7. Include conventions such as naming, structure, and commit style.
8. Include common pitfalls or gotchas specific to this repo.
9. Create `CLAUDE.md` as a symlink to `AGENTS.md` with `ln -s AGENTS.md CLAUDE.md`, skipping if it exists.
10. Print both paths and remind the user to review and commit.

After the core files are ready, offer only the project-specific lifecycle files that the repository needs:

- `.agents/setup` for fresh Amp orb dependency installation and generation. Keep it short and executable.
- `.agents/resume` for fast, idempotent reconnect repair only. It must not install dependencies.
- `.worktrees-setup` for local Crew worktree bootstrap.
- `.gate.sh` for deterministic project test, docs, and lint overrides.
- `.amp/services.yaml` for supervised development services and authenticated portals.

Do not create these optional files blindly.
Prefer calling one project-owned bootstrap command from orb and worktree setup instead of duplicating dependency logic.

Keep it short because this file loads into every agent's context for the project.
