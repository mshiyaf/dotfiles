---
name: eng-review
description: Use when reviewing an engineering approach (planned or implemented) - architecture, data flow, edge cases, failure modes, tests, and migration/operational risk.
---
## When to use
- Locking the engineering approach for a plan, or auditing an implemented change.

## Procedure - findings first, concrete risks
- Architecture and boundaries: does the data flow hold up? Coupling and ownership.
- Edge cases and failure modes, including partial failure and rollback.
- Test strategy: what proves this works, and where are the gaps?
- Backwards compatibility, migration path, and operational risk.

## Output
- Findings first, each with a concrete risk. Do not edit files.
