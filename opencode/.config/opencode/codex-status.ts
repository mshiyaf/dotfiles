/**
 * codex-status — minimal opencode TUI plugin that shows ChatGPT/Codex
 * usage and rate-limit percentages in the session prompt's right slot.
 *
 * Reads opencode's own OAuth store (~/.local/share/opencode/auth.json,
 * key "codex"), falling back to ~/.codex/auth.json (Codex CLI). Refreshes
 * the access token if expired, then calls /wham/usage and renders a
 * compact string such as "5h 72% · 1d 41%" in the bottom-right.
 *
 * No multi-account support. No persisted cache. No tools or commands.
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import type { TuiPlugin, TuiPluginModule, TuiPluginApi } from "@opencode-ai/plugin/tui";

const CODEX_CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann";
const TOKEN_URL = "https://auth.openai.com/oauth/token";
const USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";
const OPENCODE_AUTH = path.join(os.homedir(), ".local", "share", "opencode", "auth.json");
const CODEX_AUTH = path.join(os.homedir(), ".codex", "auth.json");

const REFRESH_INTERVAL_MS = 5 * 60 * 1000;
const POST_TURN_DELAY_MS = 750;
const SKEW_MS = 60_000;

type Creds = {
  accessToken: string;
  refreshToken: string;
  expiresMs: number;
  accountId?: string;
  save: (next: { accessToken: string; refreshToken: string; expiresMs: number; idToken?: string }) => void;
};

type UsageWindow = {
  used_percent?: number;
  limit_window_seconds?: number;
} | null;

type UsagePayload = {
  rate_limit?: { primary_window?: UsageWindow; secondary_window?: UsageWindow } | null;
};

type Limit = { label: string; leftPercent: number };

type Status =
  | { type: "loading" }
  | { type: "missing" }
  | { type: "error"; message: string }
  | { type: "ready"; limits: Limit[] };

// ---------- credential loading ----------

// Try opencode auth keys in order; opencode usually authenticates via the
// `openai` provider (which is actually ChatGPT OAuth), not `codex`.
const OPENCODE_AUTH_KEYS = ["openai", "codex"] as const;

function loadOpencode(): Creds | null {
  if (!fs.existsSync(OPENCODE_AUTH)) return null;
  let store: any;
  try {
    store = JSON.parse(fs.readFileSync(OPENCODE_AUTH, "utf8"));
  } catch {
    return null;
  }
  for (const key of OPENCODE_AUTH_KEYS) {
    const c = store?.[key];
    if (!c || c.type !== "oauth" || !c.access || !c.refresh) continue;
    return {
      accessToken: c.access,
      refreshToken: c.refresh,
      expiresMs: typeof c.expires === "number" ? c.expires : 0,
      accountId: typeof c.accountId === "string" ? c.accountId : undefined,
      save(next) {
        const current = JSON.parse(fs.readFileSync(OPENCODE_AUTH, "utf8"));
        current[key] = {
          ...current[key],
          type: "oauth",
          access: next.accessToken,
          refresh: next.refreshToken,
          expires: next.expiresMs,
        };
        const tmp = `${OPENCODE_AUTH}.tmp`;
        fs.writeFileSync(tmp, JSON.stringify(current, null, 2), { mode: 0o600 });
        fs.renameSync(tmp, OPENCODE_AUTH);
      },
    };
  }
  return null;
}

function loadCodexCli(): Creds | null {
  if (!fs.existsSync(CODEX_AUTH)) return null;
  let a: any;
  try {
    a = JSON.parse(fs.readFileSync(CODEX_AUTH, "utf8"));
  } catch {
    return null;
  }
  if (!a?.tokens?.access_token || !a?.tokens?.refresh_token) return null;
  return {
    accessToken: a.tokens.access_token,
    refreshToken: a.tokens.refresh_token,
    expiresMs: 0,
    accountId: a.tokens.account_id,
    save(next) {
      const current = JSON.parse(fs.readFileSync(CODEX_AUTH, "utf8"));
      current.tokens = {
        ...current.tokens,
        access_token: next.accessToken,
        refresh_token: next.refreshToken,
        id_token: next.idToken ?? current.tokens.id_token,
      };
      current.last_refresh = new Date().toISOString();
      const tmp = `${CODEX_AUTH}.tmp`;
      fs.writeFileSync(tmp, JSON.stringify(current, null, 2), { mode: 0o600 });
      fs.renameSync(tmp, CODEX_AUTH);
    },
  };
}

function loadCreds(): Creds | null {
  return loadOpencode() ?? loadCodexCli();
}

function decodeJwt(token: string): Record<string, any> | null {
  try {
    const part = token.split(".")[1];
    if (!part) return null;
    const padded = part + "=".repeat((4 - (part.length % 4)) % 4);
    return JSON.parse(Buffer.from(padded, "base64").toString("utf8"));
  } catch {
    return null;
  }
}

function expiresSoon(c: Creds): boolean {
  const now = Date.now();
  if (c.expiresMs > 0) return c.expiresMs <= now + SKEW_MS;
  const claims = decodeJwt(c.accessToken);
  const exp = typeof claims?.exp === "number" ? claims.exp : 0;
  if (!exp) return true;
  return exp * 1000 <= now + SKEW_MS;
}

function accountIdFromJwt(token: string, fallback?: string): string | undefined {
  const claims = decodeJwt(token);
  const id = claims?.["https://api.openai.com/auth"]?.chatgpt_account_id;
  if (typeof id === "string" && id.trim()) return id;
  return fallback;
}

async function refresh(c: Creds): Promise<Creds> {
  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: c.refreshToken,
      client_id: CODEX_CLIENT_ID,
    }),
  });
  if (!res.ok) throw new Error(`refresh ${res.status}`);
  const data = (await res.json()) as {
    access_token: string;
    refresh_token?: string;
    id_token?: string;
    expires_in?: number;
  };
  const expiresMs =
    typeof data.expires_in === "number" ? Date.now() + data.expires_in * 1000 : 0;
  const next = {
    accessToken: data.access_token,
    refreshToken: data.refresh_token ?? c.refreshToken,
    expiresMs,
    idToken: data.id_token,
  };
  c.save(next);
  return { ...c, ...next };
}

async function ensureFresh(c: Creds): Promise<Creds> {
  return expiresSoon(c) ? await refresh(c) : c;
}

async function fetchUsage(c: Creds): Promise<UsagePayload> {
  const accountId = accountIdFromJwt(c.accessToken, c.accountId);
  if (!accountId) throw new Error("no account id");
  const res = await fetch(USAGE_URL, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${c.accessToken}`,
      "chatgpt-account-id": accountId,
      "OpenAI-Beta": "responses=experimental",
      originator: "codex_cli_rs",
      accept: "application/json",
    },
  });
  if (!res.ok) throw new Error(`usage ${res.status}`);
  return (await res.json()) as UsagePayload;
}

// ---------- formatting ----------

function windowLabel(seconds?: number): string {
  if (!seconds || seconds <= 0) return "?";
  const minutes = Math.ceil(seconds / 60);
  if (minutes % 1440 === 0) return `${minutes / 1440}d`;
  if (minutes % 60 === 0) return `${minutes / 60}h`;
  return `${minutes}m`;
}

function toLimit(w: UsageWindow): Limit | null {
  if (!w || typeof w.used_percent !== "number") return null;
  const left = Math.round(Math.max(0, Math.min(100, 100 - w.used_percent)));
  return { label: windowLabel(w.limit_window_seconds), leftPercent: left };
}

function parseStatus(payload: UsagePayload): Status {
  const limits: Limit[] = [];
  const p = toLimit(payload.rate_limit?.primary_window ?? null);
  const s = toLimit(payload.rate_limit?.secondary_window ?? null);
  if (p) limits.push(p);
  if (s) limits.push(s);
  if (limits.length === 0) return { type: "error", message: "no limits" };
  return { type: "ready", limits };
}

function formatStatus(s: Status): string {
  switch (s.type) {
    case "loading":
      return "";
    case "missing":
      return "codex: no auth";
    case "error":
      return `codex: ${s.message}`;
    case "ready":
      return s.limits.map((l) => `${l.label} ${l.leftPercent}%`).join(" · ");
  }
}

function statusColor(s: Status, theme: TuiPluginApi["theme"]["current"]): string {
  if (s.type === "loading") return theme.textMuted;
  if (s.type !== "ready") return theme.warning;
  const min = Math.min(...s.limits.map((l) => l.leftPercent));
  if (min <= 10) return theme.error;
  if (min <= 25) return theme.warning;
  return theme.success;
}

// ---------- plugin ----------

const tui: TuiPlugin = async (api) => {
  const [solid, solidJs] = await Promise.all([
    import("@opentui/solid"),
    import("solid-js"),
  ]);

  const [status, setStatus] = solidJs.createSignal<Status>({ type: "loading" });
  let inFlight = false;

  async function tick() {
    if (inFlight) return;
    inFlight = true;
    try {
      const c = loadCreds();
      if (!c) {
        setStatus({ type: "missing" });
        return;
      }
      const fresh = await ensureFresh(c);
      const payload = await fetchUsage(fresh);
      setStatus(parseStatus(payload));
    } catch (err) {
      setStatus({ type: "error", message: (err as Error).message });
    } finally {
      inFlight = false;
    }
  }

  tick();
  const timer = setInterval(tick, REFRESH_INTERVAL_MS);
  api.lifecycle.onDispose(() => clearInterval(timer));

  const offMsg = api.event.on("message.updated", (event: any) => {
    const info = event?.properties?.info;
    if (info?.role === "assistant" && typeof info?.time?.completed === "number") {
      setTimeout(tick, POST_TURN_DELAY_MS);
    }
  });
  api.lifecycle.onDispose(offMsg);

  const offIdle = api.event.on("session.idle", () => tick());
  api.lifecycle.onDispose(offIdle);

  api.slots.register({
    slots: {
      session_prompt_right: () => {
        const node = solid.createElement("text");
        solid.spread(
          node,
          {
            get content() {
              return formatStatus(status());
            },
            get fg() {
              return statusColor(status(), api.theme.current);
            },
            selectable: false,
            truncate: true,
            wrapMode: "none",
          },
          false,
        );
        return node;
      },
    },
  });
};

const plugin: TuiPluginModule & { id: string } = {
  id: "codex-status",
  tui,
};

export default plugin;
