---
name: refactor-planner
description: Use when planning refactors, module extraction, dependency cleanup, architecture simplification, or safe incremental rewrites.
---
## Procedure
- Define the behavior that must not change.
- Separate mechanical changes from behavior changes.
- Identify seams, tests, and rollback points.
- Plan small reviewable steps.
- Keep public contracts stable unless explicitly changing them.
- Avoid broad rewrites without measurable benefit.
