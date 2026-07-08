---
name: browser
description: Use for web browsing, QA, and scraping - headless, CLI-driven, no visible window. Fetch page text, screenshot, click, fill forms, assert elements, run accessibility scans.
---
## When to use
- You need the rendered content of a page, a screenshot, or to drive a UI flow for QA.
- Use this for any web browsing/QA instead of a headed browser.

## Tool
A Bun script `browser-cli.ts` sits next to this SKILL.md (the skills dir is shared across
agents, so any host's path works). It reads one JSON operation (argument or stdin) and
prints a JSON result. Invoke it by absolute path:

```bash
bun ~/.config/opencode/skills/browser/browser-cli.ts '{"op":"text","url":"https://example.com"}'
# (equivalently ~/.claude/skills/browser/browser-cli.ts - same file)
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
- If Playwright is installed it drives a real Chromium. If not, `text` degrades to a
  plain fetch + tag-strip (JS-rendered content will be limited); non-`text` ops report
  that Playwright is required (`bunx playwright install chromium`).

## Procedure
- Prefer `text` and `assert` for cheap checks; only `screenshot` when a visual is needed.
- Report findings, not raw HTML dumps. Keep screenshots out of the repo (write to a temp dir).
- For QA flows, chain ops (fetch → assert states → screenshot) and summarize pass/fail.
