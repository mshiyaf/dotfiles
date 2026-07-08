#!/usr/bin/env bun
/**
 * Headless browser CLI for OpenCode. Reads one JSON operation (first arg or stdin),
 * prints one JSON result. Uses Playwright when available; degrades to fetch for `text`.
 *
 *   bun browser-cli.ts '{"op":"text","url":"https://example.com"}'
 *   echo '{"op":"screenshot","url":"..."}' | bun browser-cli.ts
 */

type Op = {
  op: "text" | "screenshot" | "click" | "fill" | "assert" | "axe";
  url: string;
  selector?: string;
  fields?: Record<string, string>;
  submit?: string;
  path?: string;
  fullPage?: boolean;
  waitFor?: string;
  timeout?: number;
  headless?: boolean;
};

function out(result: unknown): never {
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
  process.exit(0);
}
function fail(error: string, extra: Record<string, unknown> = {}): never {
  process.stdout.write(JSON.stringify({ ok: false, error, ...extra }, null, 2) + "\n");
  process.exit(1);
}

async function readInput(): Promise<Op> {
  const arg = process.argv[2];
  let raw = arg;
  if (!raw || raw === "-") {
    raw = await new Response(Bun.stdin.stream()).text();
  }
  if (!raw?.trim()) fail("no operation provided (pass JSON as arg or stdin)");
  try {
    return JSON.parse(raw) as Op;
  } catch (e) {
    fail("invalid JSON operation", { detail: String(e) });
  }
}

async function loadPlaywright(): Promise<any | null> {
  try {
    return await import("playwright");
  } catch {
    return null;
  }
}

// Fallback: plain fetch + crude tag strip (no JS execution).
async function fetchText(url: string): Promise<never> {
  try {
    const res = await fetch(url, { headers: { "user-agent": "Mozilla/5.0 (headless)" } });
    const html = await res.text();
    const text = html
      .replace(/<script[\s\S]*?<\/script>/gi, "")
      .replace(/<style[\s\S]*?<\/style>/gi, "")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    out({ ok: true, op: "text", url, status: res.status, engine: "fetch", text });
  } catch (e) {
    fail("fetch failed", { detail: String(e) });
  }
}

const op = await readInput();
if (!op.url) fail("missing 'url'");
const timeout = op.timeout ?? 30000;

const pw = await loadPlaywright();
if (!pw) {
  if (op.op === "text") await fetchText(op.url);
  fail(`op '${op.op}' requires Playwright`, {
    hint: "install with: bun add playwright && bunx playwright install chromium",
  });
}

// The module may be present but the browser binary not yet downloaded.
let browser: any;
try {
  browser = await pw.chromium.launch({ headless: op.headless ?? true });
} catch (e) {
  if (op.op === "text") await fetchText(op.url);
  fail(`op '${op.op}' requires a Chromium binary`, {
    detail: String(e),
    hint: "install it with: bunx playwright install chromium",
  });
}
try {
  const page = await browser.newPage();
  await page.goto(op.url, { waitUntil: "domcontentloaded", timeout });
  if (op.waitFor) await page.waitForSelector(op.waitFor, { timeout });

  switch (op.op) {
    case "text": {
      const text = (await page.evaluate(() => document.body?.innerText ?? "")).trim();
      out({ ok: true, op: "text", url: page.url(), engine: "playwright", text });
    }
    case "assert": {
      if (!op.selector) fail("assert requires 'selector'");
      const count = await page.locator(op.selector).count();
      out({ ok: true, op: "assert", selector: op.selector, exists: count > 0, count });
    }
    case "screenshot": {
      const path = op.path ?? `/tmp/opencode-shot-${Date.now()}.png`;
      await page.screenshot({ path, fullPage: op.fullPage ?? true });
      out({ ok: true, op: "screenshot", path, url: page.url() });
    }
    case "click": {
      if (!op.selector) fail("click requires 'selector'");
      await page.click(op.selector, { timeout });
      await page.waitForLoadState("domcontentloaded", { timeout }).catch(() => {});
      const text = (await page.evaluate(() => document.body?.innerText ?? "")).trim();
      out({ ok: true, op: "click", url: page.url(), text });
    }
    case "fill": {
      if (!op.fields) fail("fill requires 'fields'");
      for (const [sel, val] of Object.entries(op.fields)) {
        await page.fill(sel, val, { timeout });
      }
      if (op.submit) {
        await page.click(op.submit, { timeout });
        await page.waitForLoadState("domcontentloaded", { timeout }).catch(() => {});
      }
      out({ ok: true, op: "fill", url: page.url(), submitted: Boolean(op.submit) });
    }
    case "axe": {
      // Inject axe-core from CDN; if blocked, report gracefully.
      try {
        await page.addScriptTag({ url: "https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.9.1/axe.min.js" });
        const results = await page.evaluate(async () => await (window as any).axe.run());
        const violations = (results?.violations ?? []).map((v: any) => ({
          id: v.id, impact: v.impact, help: v.help, nodes: v.nodes.length,
        }));
        out({ ok: true, op: "axe", url: page.url(), violations });
      } catch (e) {
        fail("axe scan failed (could not load axe-core)", { detail: String(e) });
      }
    }
    default:
      fail(`unknown op '${(op as Op).op}'`);
  }
} finally {
  await browser.close();
}
