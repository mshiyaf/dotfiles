---
description: Seed a .gate.sh ship-gate config in the current repo.
agent: build
---
Set up the ship gate for this repo.

Context:
!`test -f .gate.sh && echo "exists" || echo "missing"`
!`find . -maxdepth 2 -type f \( -name 'package.json' -o -name 'composer.json' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'pyproject.toml' -o -name 'Makefile' \) | sort | head -20`

Steps:
1. If `.gate.sh` already exists, show it and stop.
2. Otherwise run `gate init` to seed it:
   !`gate init 2>&1 || true`
3. Read the manifests above and tell the user the correct `GATE_TEST` / `GATE_LINT`
   commands to set for this stack (e.g. `go test ./...`, `php artisan test`, `pytest`).
   Offer to edit `.gate.sh` accordingly. Do not commit.
