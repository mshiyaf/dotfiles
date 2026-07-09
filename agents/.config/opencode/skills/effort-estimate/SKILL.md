---
name: effort-estimate
description: Use when estimating effort, timeline, cost, budget, phases, or rough quotation for client work. Defaults to INR unless another currency is specified.
---

# Effort Estimate

Use this skill to give a structured effort, timeline, and cost response.
Do not create a proposal document unless the user explicitly asks for one.

## Defaults

- Default currency is INR / rupees unless the user specifies another currency.
- Give ranges when requirements are incomplete.
- Ask only the smallest blocking questions if a safe estimate cannot be made.
- Prefer phase-wise delivery when scope is large, risky, or budget-sensitive.
- Make hidden work visible: discovery, architecture, UX, development, integrations, testing, deployment, training, documentation, support, hosting, monitoring, and data migration.
- Separate one-time implementation, recurring AMC/support, hosting/infrastructure, and third-party charges.
- Do not expose internal AI usage, team constraints, or shortcuts.
- Account for AI-assisted delivery improving implementation speed, but do not reduce estimates drastically based only on faster coding.
- Keep QA, review, architecture, integration, deployment, support, and ownership time in the estimate.
- Prefer passing some efficiency benefit to the client through a reasonable reduction or tighter timeline while protecting quality and commercial sustainability.

## Estimation Rules

- State assumptions before numbers when assumptions affect cost or timeline.
- Include buffer for integrations, data migration, approvals, WhatsApp/API work, ERP/accounting flows, compliance, and unclear third-party systems.
- Do not underprice by omitting QA, deployment, handover, documentation, or support.
- Do not price only from raw coding hours. Price from delivered value, complexity, risk, accountability, and support responsibility.
- If the client is budget-sensitive, reduce scope or split phases before cutting quality.
- Mark optional items separately from core scope.
- Mention exclusions explicitly when they could become unpaid obligations later.
- If the request is only for a quick estimate, keep the response compact.

## Output Format

Use this structure by default:

```markdown
**Quick Verdict**
[One-line feasibility and commercial posture]

**Assumptions**
- ...

**Scope Considered**
- ...

**Effort Breakdown**
| Area | Work Included | Effort |
|---|---|---:|

**Timeline**
| Phase | Duration | Notes |
|---|---:|---|

**Cost Estimate**
| Component | Amount |
|---|---:|

**Optional / Add-On Items**
| Item | Estimated Cost |
|---|---:|

**Risks and Clarifications**
- ...

**Suggested Commercial Position**
[How to present the estimate without overcommitting]
```

## Review Before Answering

- Are timeline, cost, and scope internally consistent?
- Are third-party costs and recurring costs separated?
- Are AMC/support obligations clear?
- Is the payment or commercial posture safe for the amount of work?
- Could any wording create unpaid future obligations?
