---
name: debugging
description: Use when diagnosing bugs, failing tests, build errors, runtime failures, flaky behavior, or performance regressions.
---
## Procedure
- For complex or repeated failures, load `systematic-debugging` and follow its phases.
- Reproduce the failure or gather enough evidence.
- Read exact errors and stack traces.
- Check recent changes and environment differences.
- Trace data flow to the earliest wrong value or state.
- Form one hypothesis at a time.
- Test the hypothesis with the smallest command or change.
- Fix root cause, not symptoms.
- Add or update regression tests when possible.

## Output format
- Reproduction or evidence gathered.
- Suspected root cause and confidence.
- Smallest proposed fix.
- Verification command or manual check.
