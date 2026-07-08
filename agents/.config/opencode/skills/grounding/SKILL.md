---
name: grounding
description: Use when the agent might be hallucinating API signatures, library versions, or configuration syntax. Forces verification against actual code.
---
## Procedure
- Before asserting a library API exists, grep the codebase for actual usage.
- Before claiming a config key is valid, read the actual config file.
- Before suggesting a dependency version, check package.json or equivalent.
- If you cannot verify from local evidence, state "UNVERIFIED" and suggest the researcher agent.
- Never invent file paths, function signatures, or configuration keys.
