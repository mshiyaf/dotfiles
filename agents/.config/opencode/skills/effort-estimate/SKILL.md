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
- Do not use fixed default pricing bands. Derive the estimate from the actual scope, complexity, risk, delivery responsibility, and client value.
- MVP means polished, tested, deployable, and usable, but scope-limited. Reduce features, not quality.
- Do not split estimates into "lean MVP" and "polished MVP" tiers unless the user explicitly asks for that structure.

## Estimation Rules

- State assumptions before numbers when assumptions affect cost or timeline.
- Include buffer for integrations, data migration, approvals, WhatsApp/API work, ERP/accounting flows, compliance, and unclear third-party systems.
- Do not underprice by omitting QA, deployment, handover, documentation, or support.
- Do not price only from raw coding hours. Price from delivered value, complexity, risk, accountability, and support responsibility.
- Do not use traditional person-day math as the main driver for agent-assisted delivery.
- Do not output person-days unless the user asks for them.
- Estimate calendar time from parallelizable delivery, QA, review, client feedback, integration access, deployment, and stabilization.
- For CRUD screens, forms, admin panels, dashboards, reports, exports, and standard web UI, apply a strong AI-assisted delivery reduction.
- For unclear requirements, ERP/accounting integrations, payment/WhatsApp/SMS integrations, data migration, security/compliance, QA/UAT, deployment, and stabilization, apply a smaller reduction.
- For normal internal dashboard, admin, CRUD, or reporting systems, high MVP estimates require a clear driver such as complex integrations, heavy migration, custom BI builder, compliance, multi-company accounting, real-time sync, or strict enterprise reporting.
- If the estimate seems high, explain the exact driver. If there is no clear driver, reduce the estimate.
- If the client is budget-sensitive, reduce scope or split phases before cutting quality.
- Mark optional items separately from core scope.
- Mention exclusions explicitly when they could become unpaid obligations later.
- If the request is only for a quick estimate, keep the response compact.
- Always include a short WhatsApp-shareable version before the detailed estimate.
- The WhatsApp version must be plain text, table-free, concise, and safe to send to a client after light review.

## Calculation Method

Break the request down before estimating:

- Data inputs: manual entry, Excel/CSV import, existing database, ERP/accounting source, live API, or real-time sync.
- Masters and admin screens: clients, items, users, categories, branches, roles, settings, and configuration.
- Core workflows: approvals, transactions, status flows, validations, reminders, and exception handling.
- Dashboards and reports: KPI cards, charts, drill-downs, filters, aging, exports, scheduled reports, and custom formats.
- Integrations: ERP, accounting, payment gateway, WhatsApp, SMS, email, maps, bank, government, or third-party APIs.
- Migration/import: historical data, opening balances, cleansing, reconciliation, and validation.
- Security and access control: roles, permissions, audit logs, sensitive data, and compliance.
- Deployment and support: hosting, backups, monitoring, handover, training, stabilization, and AMC.

Use these drivers to calculate timeline and cost:

- Implementation effort after AI-assisted acceleration.
- Non-compressible review, QA, UAT, feedback, deployment, and stabilization time.
- Integration and data uncertainty.
- Business value and operational importance.
- Long-term ownership and support responsibility.
- Commercial sustainability.

Compare against prior proposal style when context is available.
Do not overestimate common internal business systems compared to larger ERPNext, event automation, or multi-module platform proposals unless the complexity clearly justifies it.

## Output Format

Use this structure by default:

```markdown
**WhatsApp Shareable Version**
[Short client-friendly summary in plain text. Include MVP timeline/cost, full system timeline/cost if relevant, major exclusions, and next step. Do not use tables.]

**Quick Verdict**
[One-line feasibility and commercial posture]

**Assumptions**
- ...

**Scope Considered**
- ...

**Scope Complexity**
| Area | Complexity | Notes |
|---|---|---|

**MVP Scope**
- ...

**Full System Scope**
- ...

**Timeline and Cost**
| Version | Timeline | Cost | Why |
|---|---:|---:|---|

**Separately Priced Items**
| Item | Estimated Cost |
|---|---:|

**Recurring Costs**
- ...

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
