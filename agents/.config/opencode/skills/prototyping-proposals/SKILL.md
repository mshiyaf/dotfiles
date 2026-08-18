---
name: prototyping-proposals
description: Creates client-facing prototype plans, HTML prototypes, image briefs, and image-generation prompts from proposal drafts. Use after proposal drafting or review when an initial client conversation needs visuals, mockups, clickable demos, or concept images.
---

# Prototyping Proposals

Use this skill to turn a proposal, SOW, requirement note, or discovery summary into client-facing visual material.
The goal is to help an early client conversation feel concrete without accidentally expanding contractual scope.

## Positioning

- Treat prototypes as illustrative sales and discovery aids, not committed deliverables unless the proposal explicitly says so.
- Keep prototype content aligned with the current proposal scope, assumptions, exclusions, timeline, and commercial boundaries.
- Prefer a small number of high-signal screens or images over a broad fake product.
- Do not expose internal AI usage, agent names, or generation workflow in client-facing material.
- If the proposal is vague, make practical assumptions and label them in the internal notes or handoff.

## Inputs To Inspect First

- The current proposal draft, SOW, client notes, or requirement document.
- Any brand assets, website links, screenshots, product references, or sample proposals supplied by the user.
- Business and proposal preferences supplied by the harness or `~/OPINIONS.md` when available.
- Voice guidance supplied by the harness or `~/VOICE.md` when available if writing client-facing explanation text.
- Continue without optional personal context when it is unavailable in an orb, and state that limitation when it materially affects the result.

## Recommended Flow

1. Identify the proposal's buyer, end users, core workflow, and strongest business outcome.
2. Select the smallest prototype package that improves the client conversation.
3. Extract only in-scope modules, data, roles, reports, dashboards, and integrations.
4. Produce one of the output modes below.
5. Add a short client-safe note that the prototype is for visual alignment and final UI may change during discovery.
6. If files are created, include a concise handoff explaining what was generated, how to open it, and what is intentionally not covered.

## Output Modes

### Prototype Plan

Use when the user wants direction before generating files.
Return:

- Prototype objective.
- Target audience and conversation goal.
- Recommended screens, images, or demo states.
- Visual style direction.
- Required assets or missing inputs.
- Risks where a visual could imply extra scope.

### HTML Prototype

Use when the user asks for an HTML prototype, clickable mockup, landing page, dashboard, portal, or screen set.

- Generate repo-native HTML, CSS, and JavaScript using the current project stack when one exists.
- If there is no project stack, prefer a single self-contained `index.html` or a clearly named prototype file under an existing docs/prototype folder if present.
- Match any provided brand colors, typography, logo, screenshots, or website style.
- Include realistic sample data derived from the proposal, but do not invent sensitive client data.
- Cover desktop and mobile layouts where useful.
- Include important states such as empty, loading, error, approval pending, or report filtered views when they affect the sales story.
- Keep interactions simple and stable: tabs, filters, navigation, modal previews, or static flows are usually enough.
- Do not add production dependencies unless the existing project already uses them and the prototype needs them.

### Image Briefs And Prompts

Use when the user needs hero images, app screenshots, concept art, workflow illustrations, pitch-deck visuals, or visual references.

Return image prompts with:

- Purpose and placement, such as proposal cover, pitch deck, landing hero, dashboard mockup, or process diagram.
- Aspect ratio and suggested dimensions.
- Brand colors, typography direction, visual mood, composition, and subject matter.
- Text to include or avoid.
- Negative instructions to avoid generic stock visuals, fake logos, unreadable UI text, or overpromising features.

When the user explicitly wants generated raster images, use an image-generation tool available in the current harness.
If image generation is unavailable, produce precise prompts instead.
For Amp specifically, only call the painter tool if the user explicitly asks to use the painter tool.

### Review Mode

Use when reviewing visuals or a prototype generated from a proposal.
Findings first, check:

- Whether visuals match the proposal scope and commercial boundaries.
- Whether the UI implies unquoted modules, automation, integrations, mobile apps, AI, or reporting.
- Whether copy is client-safe and avoids internal delivery details.
- Whether the design looks credible, specific, responsive, and not generic AI output.
- Whether the prototype has enough states to support the client conversation.

## Client-Safe Disclaimer

Use a short note like this when sharing a prototype externally:

> This prototype is a visual reference for discussion and alignment.
> Final screens, workflows, and copy will be refined during discovery and implementation within the agreed proposal scope.

## Default Recommendation

After a proposal draft and review, recommend one of these packages:

- Small website or app: 3 to 5 HTML screens covering the main user journey, admin view, and one empty/error state.
- ERP, CRM, or operations system: dashboard, master-data screen, transaction workflow, approval/report view, and role-specific navigation.
- Marketing or brand-heavy project: cover image, landing hero, 2 screen mockups, and 1 workflow/process visual.
- Early pre-sales conversation: prototype plan plus image prompts first unless the user already requested generated files.

Creating requested prototype files inside the current sandbox or repository is reversible and needs no additional approval.
Require explicit approval before publishing, externally sharing, or sending the generated material unless the current request already authorized that exact action.
