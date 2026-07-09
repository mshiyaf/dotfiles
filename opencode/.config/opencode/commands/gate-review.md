---
description: Structured review of the branch diff for the ship gate - emit JSON findings classified auto_fix vs ask_user. Output only JSON.
agent: reviewer
---
Review this branch's committed changes for the ship gate and output findings as a single JSON
object.

Rules:
- Output only JSON - no prose, no markdown fences, nothing before or after.
- Shape: {"findings":[{"id":"F1","severity":"high|medium|low","class":"auto_fix|ask_user","file":"path/to/file","line":0,"summary":"one-line problem","suggested_fix":"concrete instruction"}]}
- If there is nothing to flag, output {"findings":[]}.
- auto_fix means safe, mechanical, and unambiguous.
- ask_user means the finding needs human judgment, including logic, security, performance, architecture, public API, or behavior decisions.
- Be conservative with auto_fix. When in doubt, classify as ask_user.
- suggested_fix must be specific enough to apply directly.

Diff (branch vs its base):
!`base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main); git diff "$(git merge-base "$base" HEAD 2>/dev/null || echo "$base")"...HEAD 2>/dev/null | sed -n '1,4000p'`

Output **only** the JSON object.
