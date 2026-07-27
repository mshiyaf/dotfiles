---
name: systematic-debugging
description: Use for bugs, failing tests, build errors, runtime failures, flaky behavior, and performance regressions that need root-cause investigation.
---
Vendored from `obra/superpowers/systematic-debugging` and trimmed for global OpenCode use.

## Core rule
Do not propose or apply a fix until you have enough evidence for the root cause.

## When to use
- Test failures.
- Production or local bugs.
- Build failures.
- Unexpected behavior.
- Integration or environment issues.
- Performance regressions.
- Any issue where a quick guess seems tempting.

## Phase 1: Root cause investigation
- Read the exact error, warning, stack trace, file path, line number, and exit code.
- Before theorizing, name and run one red-capable command that detects the user's exact symptom deterministically and is practical for an agent to rerun.
- If the exact symptom cannot be automated, document the nearest executable signal and what it does not prove.
- Reproduce the issue reliably and minimize the reproduction when that shortens the feedback loop without changing the symptom.
- Check recent changes: diffs, commits, dependency updates, config, and environment.
- Trace the data or control flow backward to the earliest wrong value, state, or assumption.
- For multi-component systems, add or request diagnostic output at each boundary before guessing.

## Phase 2: Pattern analysis
- Find similar working code in the same repository.
- Compare working and broken paths.
- Identify assumptions, dependencies, config, and inputs that differ.
- Do not assume a small difference is irrelevant without evidence.

## Phase 3: Hypothesis testing
- State one clear hypothesis: `I think X is failing because Y`.
- For difficult failures, maintain 3-5 ranked, falsifiable hypotheses and update the ranking as evidence arrives.
- State the predicted observation before each probe.
- Test one variable at a time.
- Use the smallest command, instrumentation, or code change that can confirm or reject the hypothesis.
- If rejected, return to evidence gathering instead of stacking fixes.

## Phase 4: Implementation
- Prefer a failing regression test before fixing when feasible.
- Make the smallest targeted fix for the confirmed root cause.
- Verify the narrow regression first, then the broader relevant test suite.
- Rerun the original, unminimized user scenario as well as the minimized reproduction.
- Remove temporary instrumentation, debug markers, and throwaway harnesses, or explicitly document why an artifact remains.
- If three fixes fail, stop and question the design or assumptions before trying another patch.

## Red flags
- "Just try this" without evidence.
- Fixing the symptom but not explaining the cause.
- Changing multiple unrelated things at once.
- Skipping the failure reproduction.
- Ignoring a stack trace or test failure message.
- Claiming completion without rerunning the relevant check.
- Treating the minimized test as proof without rerunning the original scenario.
