# Opinions

My engineering, product, business, and workflow viewpoints.

Agents read this, per `AGENTS.md`, when a decision would benefit from my preferences.

Keep this to durable stances, not one-off project details.
Each `###` is a stance; the bullets under it are the specifics.

## Engineering

### Prefer maintainable systems over impressive ones

- Prefer practical, maintainable systems over technically impressive ones.
- Prefer boring, proven tools unless the new tool clearly pays for itself.
- Optimize for the next person reading, debugging, deploying, or supporting the code.
- Start with simple architecture. Add complexity only when workflow, scale, compliance, or maintenance reality requires it.

### Go and PostgreSQL are my defaults, not dogma

- Go is my preferred backend language for APIs, services, integrations, infrastructure tools, and long-term maintainable products.
- PostgreSQL is the default when relational structure, reporting, auditability, and long-term stability matter.
- Use the stack that fits the project, team, budget, and maintenance context. Do not force Go, React, Flutter, ERPNext, .NET, or any tool where it does not fit.

### Code quality is risk management

- Naming, structure, consistency, logs, tests, and documentation reduce business risk, they are not decoration.
- Security should be designed early, especially for medical, financial, ERP, e-invoicing, customer, and government-related systems.
- Logs, tests, screenshots, exact error messages, and reproducible steps are better than confidence.

### Operational complexity is real work

- Do not hide hosting, backups, monitoring, certificates, server costs, compliance updates, and support.
- Treat them as part of the system, not an afterthought.

## AI and Agentic Development

### Agents are leverage, not a replacement for judgment

- AI agents are leverage, not a replacement for engineering judgment.
- Treat coding agents like fast junior-to-mid engineers: useful, but they need direction, constraints, review, and verification.
- AI should improve quality, not just speed.

### The bottleneck moved to requirements and review

- The bottleneck is shifting from writing code to clarifying requirements, designing workflows, reviewing output, testing behavior, and making product decisions.
- Good agent workflows need clear instructions, isolated changes, review loops, tests, and evidence.

### Better context produces better output

- Better context creates better agent output.
- Agents should inspect the actual code, document, proposal, or logs before making strong claims.

### Match the model to the task

- Use strong reasoning models for architecture, proposal review, debugging, business judgment, and final decisions.
- Use faster or cheaper models for first drafts, repetitive implementation, extraction, formatting, and simple refactors.

### Keep AI internal to delivery, not client-facing

- AI-generated code must still be reviewed, tested, and understood. The human owns the output.
- Do not expose internal AI shortcuts to clients. Client communication should focus on quality, scope, value, timeline, and support.

## Product

### Ship the smallest thing that delivers real value

- Ship the smallest thing that delivers real user value. Cut scope before cutting quality.
- Build around the real operational workflow, not just the screen list.
- A technically working feature is incomplete if the business process remains confusing.

### Deliver in phases

- Phase-wise delivery is often better than a large one-shot scope.
- Phase 1 should solve the core workflow and create visible value.
- Later phases can include automation, analytics, mobile apps, advanced integrations, dashboards, and refinements.

### Operational depth matters as much as UI

- For ERP, event, healthcare, van sales, fleet, POS, and compliance systems, reports, statements, approvals, returns, payments, audit trails, roles, and exceptions matter as much as UI.
- For event products, cover the full attendee and organizer journey: registration, verification, QR attendance, sessions, certificates, evaluations, notifications, sponsors, reports, and admin control.
- For compliance products like ZATCA, PEPPOL, and e-invoicing, reliability, auditability, retries, logs, monitoring, and long-term storage are part of the product.

### Positioning should be specific

- SPRDH should not sound like a generic software company.
- Strong positioning: AI and Digitization Partner for ERP, event-tech, e-invoicing, automation, open-source enterprise systems, and custom digital platforms.

## DevOps and Infrastructure

### Linux-first, observable, recoverable

- Linux-first, terminal-friendly, repairable workflows fit me best.
- Infrastructure should be observable and recoverable.
- A production system should have logs, backups, deployment notes, domain and certificate clarity, and a recovery path.

### Self-hosting with clear boundaries

- Self-hosting is valuable when ownership, cost, flexibility, or AMC value matters.
- It should always come with clear support boundaries, backups, monitoring, updates, and recovery planning.

### Open-source enterprise tools earn value through implementation

- Open-source enterprise tools are strategically useful when implemented professionally.
- ERPNext, Zammad, Metabase, Nextcloud, and similar tools are valuable because of configuration, integration, training, customization, hosting, and support - not just installation.

### Cloud cost should be intentional

- Do not overbuild infra by default, but do not underprice recurring responsibility.
- Use AWS, Lightsail, DigitalOcean, VPS, or managed services based on workload, budget, compliance, and client expectations.

## Process

### Clarify before estimating

- Clarify requirements before estimating.
- Do not ask too many clarification questions when a practical assumption can be made safely.
- When requirements are unclear, ask only the critical questions needed to avoid wrong estimation or wrong architecture.

### Define scope explicitly for client work

- Define included scope, exclusions, assumptions, timeline, payment terms, AMC, hosting, change requests, and third-party costs.
- When something is outside agreed scope, position it as a next phase or add-on, not as a refusal.

### Reviews should catch commercial and technical inconsistencies

- Proposal reviews should catch commercial inconsistencies, mismatched amounts, unclear AMC terms, spelling issues, timeline conflicts, and scope ambiguity.
- Exact change lists are more useful than generic feedback.

### Make hidden work visible

- Make hidden work visible where it matters: architecture, mentoring, support, review, deployment, hosting, monitoring, and documentation.

## Business and Pricing

### Price fair, but not weak

- Pricing should be fair, practical, and suitable for the client context, but not weak.
- It is acceptable to reduce cost for strategic clients, mentees, friends, or early-stage opportunities, but not in a way that destroys perceived value or creates unsustainable support.
- For budget-sensitive clients, reduce scope or split phases before cutting quality.

### AI-assisted delivery changes effort, not responsibility

- AI agents can reduce implementation effort significantly compared to older human-only delivery timelines.
- Proposal and estimation work should account for that efficiency, but not reduce pricing or timelines drastically just because coding is faster.
- Keep room for discovery, architecture, human review, QA, security checks, client feedback, deployment, documentation, training, stabilization, and long-term support.
- Price and timeline should reflect delivered value, risk, accountability, and support responsibility, not only raw coding hours.
- When AI-assisted delivery makes work faster, pass some benefit to the client through a reasonable timeline or cost reduction while preserving quality and commercial sustainability.

### AMC is real recurring cost

- AMC should not be treated casually.
- Recurring support, hosting, monitoring, backups, compliance changes, and client handholding have real cost.

### Proposals: confident, specific, honest

- Avoid exaggerated enterprise language, but make proposals look confident and professional.
- Avoid vague promises. State what is included, what is excluded, and what happens next.
- Client trust comes from clarity, not from saying yes to everything.

### Use official company names

- SPRDH Solutions Private Limited
- Hattec Solutions

### Use the correct proposal sender identity

- For SPRDH proposals, use:
  - SPRDH Solutions Private Limited.
  - First Floor, Kerala Startup Mission, Kerala Technology Innovation Zone, Kalamassery, Kochi, Kerala 683503, India.
  - hello@sprdh.com
  - +91 799 428 66 60
- For Texol proposals, use:
  - Texol
  - iCohort Business Ventures Pvt. Ltd
  - Pantheerankavu, Kozhikode, Kerala, India, 673019
  - support@texolworld.com
  - +91 90379 81865
- Choose the sender identity from the user's requested company, project folder, client context, or location context.
- If the proposal sender is unclear, ask one short clarification question before drafting the final proposal header.

## Client Communication

### Protect boundaries without sounding rude

- Be polite, firm, and specific while protecting scope, payment, timeline, and support boundaries.
- Do not expose internal uncertainty, AI usage, cost pressure, or team limitations unless there is a clear reason.
- Use evidence when needed: attachments, screenshots, payment confirmations, logs, exact issue descriptions, or references.
- Tone and message patterns live in `VOICE.md`.

## Career, Learning, and Mentoring

### Fundamentals still matter in the AI era

- Engineers should understand Linux, networking, databases, Git, HTTP, security, deployment, debugging, and system design.
- Beginners should build real things, not only study theory.

### Mentoring is real contribution

- Interns and mentees should learn practical workflows: terminal usage, Git, debugging, deployment, AI-assisted development, and clear communication.
- Mentoring, architecture review, planning, unblocking developers, and technical guidance are real contributions even when they are not easy to measure as task hours.

### Grow across depth and breadth

- Career growth should combine backend depth, DevOps ability, architecture judgment, product sense, and business communication.

## Accounting, ERP, and Operational Decisions

### Optimize for clarity in statements and audits

- Prefer the workflow that is clearest later in statements, reports, audits, and client explanations.
- ERP and accounting flows should not only be technically correct. They should also be understandable to users and auditors.

### Represent money movements visibly

- Opening balances, debit notes, receipts, returns, wallets, and customer statements should be represented clearly.
- When a transaction affects customer balance, it should usually be visible somewhere meaningful in the customer statement, ledger, or wallet history.
- Avoid hidden adjustments that make later reconciliation difficult.

## Personal Workflow

### Linux-first, keyboard-friendly, low-friction

- Prefer tools that are stable, scriptable, repairable, and low-friction.
- Tools should reduce repeated work, not become the work.

### Hardware for longevity over specs

- Prioritize comfort, durability, build quality, call quality, repairability, and long-term usefulness over specs alone.

### Own personal systems within reason

- For personal systems and homelab-style tools, ownership and control matter, but maintenance cost should stay reasonable.

## Default Decision Rules

- Choose clarity over cleverness.
- Choose maintainability over novelty.
- Choose scope clarity over vague flexibility.
- Choose phased delivery over risky bloated delivery.
- Choose evidence over assumptions.
- Choose business value over feature count.
- Choose simple reliable implementation over over-engineered architecture.
- Choose professional boundaries over silent unpaid work.
- Choose AI-assisted quality, not just AI-assisted speed.
