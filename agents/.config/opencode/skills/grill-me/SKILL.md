---
name: grill-me
description: Interviews the user to resolve requirements and decisions before action. Use only when the user explicitly asks to be grilled, interviewed, challenged, or questioned thoroughly.
---

# Grill Me

Build shared understanding before planning or implementation.
Do not take action until the user confirms alignment.

## Ground rules

- Investigate facts available from the repository, environment, or authoritative sources instead of asking the user.
- Ask the user only for decisions, preferences, priorities, or unavailable human context.
- Treat the subject as a dependency tree: resolve prerequisite decisions before dependent ones.
- Give a recommended answer with concise rationale for every question.
- Make assumptions visible instead of silently choosing them.
- Do not invoke this skill automatically merely because a request has minor ambiguity.

## Modes

Use **serial mode** unless the user asks for batch, frontier, or faster grilling.

### Serial mode

Ask exactly one unresolved, high-consequence question per turn and wait for the answer.

### Frontier mode

Ask one numbered batch containing every currently independent question whose prerequisites are resolved.
Do not ask questions that depend on answers still pending in the same batch.
Recompute the frontier after the user answers.

## Question format

For each decision include:

1. The question.
2. **Recommendation:** the preferred answer.
3. **Why:** the main trade-off or consequence.
4. **Reversibility:** easy to reverse, costly to reverse, externally visible, or destructive/privileged.

Spend more interview depth on costly, externally visible, destructive, or privileged decisions.
Allow the user to defer a low-risk decision by explicitly accepting the recommended default.

## Completion

Stop when all high-consequence branches are resolved and every remaining assumption is explicit.
Summarize:

- Goal
- Decisions made
- Accepted assumptions and defaults
- Scope and non-goals
- Open questions, if any
- Recommended next skill or action

Ask the user to confirm alignment before planning, editing files, dispatching agents, or publishing anything.
