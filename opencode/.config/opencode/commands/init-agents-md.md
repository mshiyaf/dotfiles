---
description: Seed a per-project AGENTS.md (+ CLAUDE.md symlink) in the current repo.
agent: build
---
Use the init-agents-md skill.

Create a project-level `AGENTS.md` if it does not already exist. Do not commit.

Context:
!`ls AGENTS.md CLAUDE.md 2>/dev/null; git rev-parse --show-toplevel 2>/dev/null`
!`find . -maxdepth 2 -type f \( -name 'package.json' -o -name 'composer.json' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'pyproject.toml' -o -name 'Makefile' \) | sort | head -20`
