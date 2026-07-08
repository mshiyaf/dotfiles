---
name: test-writer
description: Use when creating, updating, or reviewing tests for new behavior, bug fixes, refactors, or regression coverage.
---
## Procedure
- For behavior changes and bug fixes, prefer `test-driven-development` when a failing test is practical.
- Follow existing test structure and naming.
- Test observable behavior, not implementation details.
- Cover success, failure, edge cases, and regression paths.
- Prefer focused tests over broad brittle tests.
- Avoid unnecessary mocks.
- Run the narrowest relevant test first, then broader tests when appropriate.

## Test plan checklist
- Unit or function-level behavior.
- Integration boundaries and persistence.
- Error, empty, permission, and boundary cases.
- Regression case for the reported bug.
- Manual verification only when automation is not practical.
