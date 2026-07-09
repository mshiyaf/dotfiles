---
name: proposal-writing
description: Use when drafting, reviewing, or commercially checking client proposals, SOWs, implementation proposals, AMC/support terms, payment milestones, assumptions, exclusions, and deliverables.
---

# Proposal Writing

Use this skill for client proposal drafting and review.
Follow the user's proposal style: polished, specific, business-focused, scope-safe, and not generic marketing copy.

## Required Context

- Read `~/OPINIONS.md` for business, pricing, scope, AMC, and delivery preferences when available.
- Read `~/VOICE.md` when drafting or rewriting proposal text in the user's voice.
- Inspect any provided sample proposal, requirement note, existing proposal, or client document before making strong claims.
- If inputs are incomplete, make practical assumptions and list them clearly.

## Sender Identity

Use the correct sender identity in proposal headers, footers, closing notes, and contact blocks.

- SPRDH proposals:
  - SPRDH Solutions Private Limited.
  - First Floor, Kerala Startup Mission, Kerala Technology Innovation Zone, Kalamassery, Kochi, Kerala 683503, India.
  - hello@sprdh.com
  - +91 799 428 66 60
- Texol proposals:
  - Texol
  - iCohort Business Ventures Pvt. Ltd
  - Pantheerankavu, Kozhikode, Kerala, India, 673019
  - support@texolworld.com
  - +91 90379 81865

Choose the sender from the user's requested company, project folder, client context, or location context.
If it is unclear, ask one short question before drafting the final proposal header.

## DOCX Output

Do not create DOCX files unless the user explicitly requests DOCX output.
When DOCX output is requested, use the committed builder instead of improvising a converter.
The builder reuses the sanitized proposal Word template derived from the accepted sample layout.
It keeps the same proposal structure, header, footer, heading styles, numbering, and commercial table treatment while replacing the proposal content.

Run it through `uv` so dependencies are not installed globally:

```bash
uv run --with python-docx ~/.config/opencode/skills/proposal-writing/scripts/build_docx.py draft.md --company sprdh -o proposal.docx
```

Use `--company texol` for Texol proposals.
The logo follows the resolved sender identity automatically; do not pick a logo by hand.
If the company cannot be resolved to `sprdh` or `texol`, ask one short question before building the DOCX.

Expected draft frontmatter:

```yaml
---
company: sprdh
title: Techno-Commercial Proposal for Example Project
client: Example Client Pvt. Ltd
date: 09 July 2026
document_id: SP/CLIENT/090726/TCP/1.0
version: "1.0"
---
```

CLI flags override frontmatter.
Useful flags are `--title`, `--client`, `--date`, `--document-id`, `--version`, `--author`, `--approver`, and `--client-logo`.
The Markdown body may contain headings, paragraphs, bullet lists, numbered lists, inline bold/italic, and pipe tables for commercial sections.
Run the script by absolute skill path because the agent's working directory is usually the client/project folder, not the skill directory.

## Proposal Draft Structure

Use this structure unless the user asks for a different format:

1. Title / prepared for / prepared by / date
2. Executive summary or project background
3. Understanding of requirement
4. Proposed solution overview
5. Module-wise scope of work
6. User roles, workflows, reports, dashboards, and integrations where relevant
7. Technology approach or implementation approach
8. Phased timeline
9. Commercial proposal
10. Optional add-ons or future enhancements
11. Hosting, AMC, support, and third-party cost boundaries
12. Payment terms
13. Client responsibilities
14. Assumptions
15. Exclusions / out of scope
16. Deliverables
17. Closing note or proposal acceptance

## Drafting Rules

- Keep business outcomes and operational clarity ahead of technical detail.
- Avoid exaggerated enterprise language and generic software-company wording.
- Make included scope, assumptions, exclusions, payment terms, AMC, hosting, change requests, and third-party costs clear.
- Use phase-wise delivery when the scope is broad, risky, or budget-sensitive.
- MVP or Phase 1 must mean a polished, tested, deployable core system with limited scope. Do not imply that a later phase is needed to make it proper.
- Do not split proposal options into "lean MVP" and "polished MVP" unless the user explicitly asks for that commercial structure.
- Full System should mean extended scope such as integrations, automations, advanced reports, multi-branch/company support, or additional workflows.
- Explain open-source products such as ERPNext as implementation value, not license resale.
- Keep optional items separate from committed scope.
- Do not overpromise integrations, migration, automation, AI, WhatsApp, SMS, OCR, mobile apps, or reporting unless explicitly scoped.
- Do not expose internal AI usage or internal delivery shortcuts.
- AI-assisted delivery may reduce implementation effort, but proposal pricing and timelines must still include discovery, architecture, review, QA, deployment, documentation, training, stabilization, and support responsibility.
- If efficiency allows a shorter timeline or better price, reflect it reasonably without making the proposal look weak or creating unsustainable support obligations.
- Avoid em dashes. Use a plain hyphen.

## Review Checklist

For proposal review, findings should come first and be exact.
Check for:

- Scope ambiguity that can create unpaid obligations later.
- Timeline conflicts or unrealistic delivery promises.
- Commercial inconsistencies, mismatched totals, missing tax/GST/VAT notes, or weak payment milestones.
- AMC/support terms that are too broad or commercially unsafe.
- Hosting, domain, server, backup, WhatsApp/SMS/API, email gateway, map, hardware, government, and third-party charges that are not clearly included or excluded.
- Data migration, manual correction, training, UAT, go-live, and post-go-live support boundaries.
- Optional add-ons mixed into core scope.
- Missing assumptions, exclusions, client responsibilities, deliverables, or acceptance terms.
- Spelling, company-name consistency, currency consistency, and date/version consistency.

## Commercial Review Focus

For commercial review, focus on pricing sustainability and risk:

- Is the price too low for the promised scope?
- Does the estimate account for AI-assisted speed without ignoring review, QA, deployment, and accountability?
- Are recurring responsibilities priced or bounded?
- Are support hours, response expectations, and AMC exclusions clear?
- Are payment milestones safe for cash flow?
- Are third-party and infrastructure costs separated?
- Are change requests handled in writing?
- Should the work be split into phases or add-ons?

## Output Modes

- `proposal-draft`: produce proposal text or a structured draft outline, depending on the user's request.
- `proposal-review`: produce findings first, then exact suggested wording or change list.
- `proposal-commercial-review`: focus on pricing, AMC, support, hosting, third-party costs, payment terms, and scope creep.
- If the user asks only for an estimate, use `effort-estimate` instead of drafting a proposal.
