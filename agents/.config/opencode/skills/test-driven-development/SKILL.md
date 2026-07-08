---
name: test-driven-development
description: Use when implementing behavior changes or bug fixes where a failing test can define the expected behavior before code changes.
---
Vendored from `obra/superpowers/test-driven-development` and trimmed for pragmatic global OpenCode use.

## Core rule
When feasible, write or identify a failing test before changing production behavior.

## Red-green-refactor
1. Red: write one focused test for the intended behavior or bug reproduction.
2. Verify red: run it and confirm it fails for the expected reason.
3. Green: implement the smallest change that passes the test.
4. Verify green: rerun the focused test and relevant surrounding tests.
5. Refactor: clean up only after tests are green.

## When to use
- New behavior.
- Bug fixes.
- Regression fixes.
- Refactors where behavior must stay stable.
- Risky edge cases that need durable proof.

## Pragmatic exceptions
- Throwaway exploration.
- Generated files.
- Pure documentation.
- Simple configuration changes.
- Repositories with no practical test harness, where a manual verification plan is the best available option.

## Good tests
- Test observable behavior, not private implementation details.
- Use clear names that describe the behavior.
- Keep each test focused on one outcome.
- Prefer real code paths over mocks when practical.
- Add edge cases for errors, empty input, permissions, boundaries, and regression paths.

## Verification checklist
- The test fails before the fix or the existing failing test is identified.
- The failure proves the intended behavior gap.
- The implementation is minimal.
- The relevant tests pass after the change.
- No unrelated refactor or cleanup is bundled into the behavior change.
