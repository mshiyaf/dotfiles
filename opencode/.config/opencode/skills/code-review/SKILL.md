---
name: code-review
description: Use when reviewing code, diffs, staged changes, or pull requests for correctness, regressions, maintainability, and missing tests.
---
## Procedure
- Findings first, ordered by severity.
- Include file and line references when possible.
- Prioritize bugs, behavioral regressions, data loss, security, concurrency, and missing tests.
- Check whether tests cover the changed behavior and likely failure modes.
- Check API, database, and security implications when the diff touches those boundaries.
- Avoid style-only comments unless they block maintainability.
- State when no findings are found.
- Include residual risks and testing gaps.

## Severity
- Critical: exploitable security issue, data loss, broken production path, or unsafe migration.
- Important: likely bug, missed edge case, broken contract, or insufficient test coverage.
- Minor: maintainability issue worth noting but not blocking.
