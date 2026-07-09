---
description: Seed optional .gate.sh ship-gate overrides in the current repo.
agent: build
---
Create optional ship-gate overrides for this repo. `gate run` works without this file;
leave test/lint empty for agent auto-detection and docs empty to skip by default.

Context:
!`test -f .gate.sh && echo "exists" || echo "missing"`

Steps:
1. If `.gate.sh` already exists, show it and stop.
2. Otherwise run `gate init` to seed optional overrides:
   !`gate init 2>&1 || true`
3. Tell the user they can keep `GATE_TEST` and `GATE_LINT` empty for auto-detection,
   or set deterministic overrides such as `pnpm test`, `go test ./...`, `pytest`,
   or `pnpm lint`. Do not commit.
