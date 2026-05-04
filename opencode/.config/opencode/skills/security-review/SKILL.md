---
name: security-review
description: Use for security reviews of code, configuration, dependencies, APIs, auth flows, data handling, and infrastructure changes.
---
## Checklist
- Authentication and authorization boundaries.
- Injection risks in SQL, shell, templates, URLs, and serialized data.
- Secrets in code, logs, diffs, configs, or tests.
- Sensitive data exposure and overbroad logging.
- Unsafe file, network, and subprocess handling.
- Missing validation, rate limits, CSRF/CORS controls, or audit trails.
- Dependency and container configuration risk.

## Output format
- Findings first, ordered by exploitability and impact.
- Include attack path, affected asset, and likely consequence.
- Separate confirmed issues from hardening recommendations.
- If no findings are found, state residual risk and what was not reviewed.
