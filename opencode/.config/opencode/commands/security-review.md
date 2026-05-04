---
description: Security review current changes and nearby risky code.
agent: security-reviewer
---
Use the security-review skill.

Context:
!`git status --short`
!`git diff --stat`
!`git diff`
!`git diff --cached`

Focus on exploitable risk, data exposure, auth, injection, secrets, unsafe config, and dependency risk. Do not edit files.
