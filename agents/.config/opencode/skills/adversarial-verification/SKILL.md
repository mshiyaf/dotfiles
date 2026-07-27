---
name: adversarial-verification
description: Proves guardrails, validators, permissions, hooks, and invariants with controlled pass-fail-pass checks. Use when implementing or reviewing enforcement mechanisms.
---

# Adversarial Verification

Verify that an enforcement mechanism rejects a real violation, not only that its happy path succeeds.

## Pass-fail-pass protocol

1. **Pass:** run a representative valid case and observe success.
2. **Inject:** introduce one controlled, representative violation in a disposable fixture, temporary file, isolated worktree, or test environment.
3. **Fail:** run the enforcement check and confirm it fails for the expected reason.
4. **Restore:** remove only the injected violation and confirm the original state is restored.
5. **Pass again:** rerun the valid case and observe success.

## Rules

- Inspect the target before changing it.
- Prefer an existing test fixture or isolated environment over modifying shared state.
- Never test a destructive or externally visible guardrail by performing the destructive action.
- Do not expose real secrets, weaken production permissions, push, deploy, or mutate shared infrastructure.
- Test at least one likely bypass when the control parses commands, paths, roles, or configuration.
- If safe violation injection is unavailable, state the limitation and propose the smallest safe harness.
- Clean up temporary files, debug markers, and injected state before completion.

## Evidence

Report:

- Invariant being enforced
- Valid case and exact command
- Injected violation
- Expected failure
- Observed failure and reason
- Restoration step
- Final passing command
- Untested bypasses or residual risk
