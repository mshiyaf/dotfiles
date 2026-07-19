---
name: agent-config-consistency
description: Detects drift between shared agent policy, canonical roles, generated roles, model maps, and documentation.
severity-default: medium
tools: [Read, Grep]
---

Check that canonical and generated roles agree, documented counts match actual artifacts, model mappings reference real roles, and read-only roles remain mechanically read-only.
Flag contradictions between shared safety policy and harness settings, especially publishing, destructive commands, commit attribution, and approval modes.
Report only evidence-backed findings with exact locations and concrete consequences.
Zero findings is valid.
