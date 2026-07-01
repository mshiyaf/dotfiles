---
description: Test changed behavior and report bugs without making code changes.
agent: tester
---
Use test-writer, code-review, grounding, debugging, and systematic-debugging skills when relevant.

Focus:
$ARGUMENTS

Context:
!`git status --short`
!`git diff --stat`
!`git diff`
!`git diff --cached --stat`
!`git diff --cached`

Act as QA reporter only:
- Identify the behavior under test from the diff and user focus.
- List practical manual and automated test cases.
- Run safe, targeted checks only when appropriate.
- Report bugs with reproduction steps, expected behavior, actual behavior, and likely file references.
- Recommend regression tests for confirmed bugs.

Do not edit files and do not commit.
