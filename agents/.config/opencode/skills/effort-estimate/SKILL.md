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
- Assume delivery by one experienced developer using top-tier coding agents, parallel agent workflows, reusable foundations, managed services, automated testing, and established UI templates unless the user specifies another delivery model.
- Apply the full realistic implementation reduction from that delivery model rather than estimating a traditional agency team or sequential software-development lifecycle.
- Keep real QA, review, architecture, deployment, support, and ownership obligations in the estimate, but scale them to the actual application risk and avoid turning standard production practices into enterprise-sized workstreams.
- Preserve some of the productivity benefit as margin while passing a meaningful share to the client through a lower price and shorter timeline.
- Do not use fixed default pricing bands. Derive the estimate from the actual scope, complexity, risk, delivery responsibility, and client value.
- MVP means polished, tested, deployable, and usable, but scope-limited. Reduce features, not quality.
- Do not split estimates into "lean MVP" and "polished MVP" tiers unless the user explicitly asks for that structure.

## Agentic Delivery Calibration

- Treat the user's demonstrated delivery speed as the primary baseline when it is credible for the stated stack and scope.
- Estimate active implementation time first, after agentic acceleration and parallel execution.
- Separately estimate client-facing calendar time for requirements confirmation, UAT, feedback, acceptance, and stabilization.
- Do not present waiting for client feedback or a post-launch warranty period as active development time.
- Do not infer a multi-person team, traditional agency overhead, or sequential discovery, design, backend, frontend, QA, and deployment phases unless the engagement actually requires them.
- Authentication, standard role permissions, responsive admin layouts, CRUD screens, forms, tables, filters, file uploads, dashboards, basic reports, audit fields, backups, and conventional deployment are baseline application work.
- These baseline features do not independently justify a multi-month schedule or enterprise price.
- Low traffic and a single business, branch, or tenant reduce infrastructure, operational, and scalability risk.
- High traffic is only a material price driver when it requires special architecture, load testing, high availability, data partitioning, or operational support.
- Dynamic forms, inventory movements, partial payments, status workflows, and profitability calculations add correctness risk, but remain low-to-medium complexity when their rules are clear and there are no external integrations.
- For a small single-business internal CRUD or operations app with clear requirements, a reusable admin UI, no external integrations, no migration, no compliance work, and no unusual workflow, use roughly 5-10 working days of active delivery as an initial sanity check.
- For that same profile, INR 1.25-1.75 lakh, or approximately SAR 5,000-7,000 when quoting in Saudi riyals, is a reasonable commercial calibration range for implementation and a limited defect warranty.
- The calibration range is not a fixed rate card.
  Move below or above it only when the actual scope, delivery obligation, client context, or risk provides a concrete reason.
- A timeline above four calendar weeks or a price materially above the calibration range for a normal internal business app must identify the specific non-compressible drivers.
- Valid drivers include complex integrations, unclear accounting rules, substantial migration, Arabic/RTL, ZATCA or other compliance, multi-company or multi-branch behavior, offline synchronization, custom BI, strict security review, high availability, or extensive training and support.

## Estimation Rules

- State assumptions before numbers when assumptions affect cost or timeline.
- Include buffer for integrations, data migration, approvals, WhatsApp/API work, ERP/accounting flows, compliance, and unclear third-party systems.
- Do not underprice by omitting QA, deployment, handover, documentation, or support.
- Do not price only from raw coding hours. Price from delivered value, complexity, risk, accountability, and support responsibility.
- Do not use traditional person-day math as the main driver for agent-assisted delivery.
- Do not output person-days unless the user asks for them.
- Show active implementation time separately from delivery calendar time when UAT, approvals, client feedback, or stabilization materially extend the calendar.
- Estimate calendar time from parallelizable delivery, QA, review, client feedback, integration access, deployment, and stabilization without serializing work that can reasonably happen in parallel.
- For CRUD screens, forms, admin panels, dashboards, reports, exports, and standard web UI, apply a strong AI-assisted delivery reduction.
- For unclear requirements, ERP/accounting integrations, payment/WhatsApp/SMS integrations, data migration, security/compliance, extensive QA/UAT, and operational stabilization, apply a smaller reduction.
- Do not add large standalone allocations for ordinary QA, deployment, backups, documentation, or a limited defect warranty on a small conventional application.
- Do not inflate a quote merely because the client is in a higher-priced market.
  Use the requested currency and consider local commercial context, but keep the estimate anchored to actual scope, risk, responsibility, and the user's delivery model.
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
- Non-compressible review, QA, UAT, feedback, deployment, and stabilization time, scaled to actual risk.
- Integration and data uncertainty.
- Business value and operational importance.
- Long-term ownership and support responsibility.
- Commercial sustainability.

Calculate in this order:

1. Classify the application as simple, moderate, or complex using concrete scope drivers rather than the number of screens or modules.
2. Estimate active implementation time using the agentic delivery profile.
3. Add only the non-compressible calendar time and obligations that actually apply.
4. Calibrate the commercial price against the closest application profile above.
5. Increase the estimate only for named complexity, uncertainty, risk, or support drivers.
6. Reduce scope before increasing a small-business CRUD estimate into an enterprise range.

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
| Version | Active Delivery | Expected Calendar | Cost | Why |
|---|---:|---:|---:|---|

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
