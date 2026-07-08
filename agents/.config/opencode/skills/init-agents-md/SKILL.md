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

Keep it short because this file loads into every agent's context for the project.
