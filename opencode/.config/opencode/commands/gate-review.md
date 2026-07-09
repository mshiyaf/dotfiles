---
description: Structured review of the branch diff for the ship gate - emit JSON findings classified auto_fix vs ask_user. Output only JSON.
agent: reviewer
---
Review this branch's committed changes for the ship gate and output findings as a single JSON
object. Use the `gate-review` skill for the schema and classification rules.

Diff (branch vs its base):
!`base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main); git diff "$(git merge-base "$base" HEAD 2>/dev/null || echo "$base")"...HEAD 2>/dev/null | head -4000`

Output **only** the JSON object described in the gate-review skill - no prose, no markdown fences.
If there is nothing to flag, output `{"findings":[]}`.
