---
name: browser
description: Use for web browsing, QA, and scraping - headless, CLI-driven, no visible window. Fetch page text, screenshot, click, fill forms, assert elements, run accessibility scans.
---
## When to use
- You need the rendered content of a page, a screenshot, or to drive a UI flow for QA.
- Use this for any web browsing/QA instead of a headed browser.

## Tool
A Bun script `browser-cli.ts` sits next to this SKILL.md.
It reads one JSON operation from an argument or stdin and prints a JSON result.
Resolve it relative to the skill base directory reported by the current harness instead of assuming a home-directory installation path:

```bash
bun <skill-base-directory>/browser-cli.ts '{"op":"text","url":"https://example.com"}'
```

Operations (`op`):
- `text`   - `{url}` → rendered text content of the page.
- `screenshot` - `{url, path?, fullPage?}` → saves a PNG, returns its path (default: a temp file).
- `click`  - `{url, selector}` → click an element (returns resulting URL + text).
- `fill`   - `{url, fields:{selector:value,...}, submit?}` → fill a form, optional submit selector.
- `assert` - `{url, selector}` → `{exists:true|false, count}`.
- `axe`    - `{url}` → axe-core accessibility violations (if available).

Common options: `{waitFor?:selector, timeout?:ms, headless?:true}`.

## Behaviour
- Fully headless; no browser window is ever shown.
- Prefer browser or web tools built into the current harness when they provide the required operation.
- Amp orbs include Bun and `agent-browser`, but this fallback script still needs Playwright for browser-driving operations.
- If Playwright is installed it drives a real Chromium. If not, `text` degrades to a
  plain fetch + tag-strip (JS-rendered content will be limited); non-`text` ops report
  that Playwright is required. Do not install browser dependencies unless the task requires them.

## Procedure
- Prefer `text` and `assert` for cheap checks; only `screenshot` when a visual is needed.
- Report findings, not raw HTML dumps. Keep screenshots out of the repo (write to a temp dir).
- For QA flows, chain ops (fetch → assert states → screenshot) and summarize pass/fail.
- Treat sandbox-local development services as reversible test targets.
- Before submitting a form or performing another write against an external or shared service, require explicit user approval unless the current request already authorized that exact action.
