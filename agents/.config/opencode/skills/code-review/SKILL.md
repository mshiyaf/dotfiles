---
name: code-review
description: Use when reviewing code, diffs, staged changes, or pull requests for correctness, regressions, maintainability, and missing tests.
---
## Procedure
- Establish the review fixed point before judging the change:
  - For a branch or PR, identify the base and review the merge-base three-dot diff through the current HEAD.
  - For staged or working-tree work, capture the requested staged/unstaged snapshot and do not silently change scope during review.
- Find the source requirement: user request, accepted plan, specification, ticket, or acceptance criteria.
- Find applicable standards: `AGENTS.md`, project documentation, public contracts, and established nearby patterns.
- If no source requirement is available, say that Spec fidelity is unverified and distinguish explicit evidence from inferred intent.
- Review two independent axes:
  - **Spec:** missing behavior, incorrect behavior, unmet acceptance criteria, and unrequested scope.
  - **Standards:** correctness, regressions, maintainability, repository conventions, and test quality.
- For large or high-risk diffs, use independent read-only reviewers for Spec and Standards when the harness supports parallel review.
- Findings first, ordered by severity.
- Tag each finding `[Spec]` or `[Standards]`; use both only when the evidence genuinely spans both axes.
- Include file and line references when possible.
- Prioritize bugs, behavioral regressions, data loss, security, concurrency, and missing tests.
- Check whether tests cover the changed behavior and likely failure modes.
- Check API, database, and security implications when the diff touches those boundaries.
- Avoid style-only comments unless they block maintainability.
- State when no findings are found.
- Include residual risks and testing gaps.
- Do not edit files.

## Severity
- Critical: exploitable security issue, data loss, broken production path, or unsafe migration.
- Important: likely bug, missed edge case, broken contract, or insufficient test coverage.
- Minor: maintainability issue worth noting but not blocking.
