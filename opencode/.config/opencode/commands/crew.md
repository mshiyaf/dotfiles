---
description: Captain - split a multi-feature request into tasks, dispatch a crewmate per feature, monitor, and report ready branches.
agent: captain
---
Orchestrate parallel agents to build several features at once. Use the `crew` skill.

Request: $ARGUMENTS

Context:
!`git rev-parse --show-toplevel 2>/dev/null || echo "not in a git repo"`
!`crew status 2>/dev/null || echo "no crewmates yet"`

Steps:
1. If the request is empty, ask what to build. If not in a git repo, say so and stop.
2. Split the request into independent features (see the crew skill). Merge or sequence any that
   would edit the same core files.
3. For each feature, choose a profile: `fast` for mechanical docs/formatting, `standard` for normal
   implementation/tests, or `deep` for architecture-sensitive, concurrent, security-sensitive, or difficult
   debugging work. Dispatch a crewmate with a crisp, self-contained task:
   `crew new --profile <fast|standard|deep> "<task>"`.
4. Report the dispatched crewmates and how to check in (`crew status`, `crew logs <branch>`, and
   `crew watch` in a separate pane for push alerts when one is ready or blocked), then **stop and
   hand control back to the user**. Do not loop on `crew status` - there is no live watcher, and
   continuous polling just spams the user and burns tokens.
5. Only when the user asks to check in, run `crew status` once and summarize: still running, blocked
   (surface the `BLOCKED:` reason and ask how to proceed), or done. A crewmate that is `done` with
   commits-ahead > 0 is ready for review.
6. Hand the ready branches back to the user to review (`/review-diff`) and ship (`/ship-gate`).
   Never push or merge yourself.
