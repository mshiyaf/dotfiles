/**
 * codex-status - minimal opencode TUI plugin that shows ChatGPT/Codex
 * usage and rate-limit percentages in the session prompt's right slot.
 *
 * Reads opencode's own OAuth store (~/.local/share/opencode/auth.json),
 * falling back to the Codex CLI OAuth store (~/.codex/auth.json). Refreshes
 * the access token if expired, then calls /wham/usage and renders a
 * compact string such as "5h █████░░░░░ 55% · 7d ██░░░░░░░░ 20%" in the bottom-right.
 *
 * No multi-account support. No persisted cache. No tools or commands.
 */

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { Database } from "bun:sqlite";
import type { TuiPlugin, TuiPluginModule, TuiPluginApi } from "@opencode-ai/plugin/tui";

const CODEX_CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann";
const TOKEN_URL = "https://auth.openai.com/oauth/token";
const USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";
const OPENCODE_AUTH = path.join(os.homedir(), ".local", "share", "opencode", "auth.json");
const CODEX_AUTH = path.join(os.homedir(), ".codex", "auth.json");
const OPENCODE_DB = path.join(os.homedir(), ".local", "share", "opencode", "opencode.db");

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
type ContextUsage = { tokens: number; percent: number };
type ContextSample = { tokens: number; providerID?: string; modelID?: string };
type Theme = TuiPluginApi["theme"]["current"];
type ThemeColor = Theme["text"];

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

function bar(percent: number): string {
  const width = 10;
  let filled = Math.round((percent / 100) * width);
  if (percent > 0 && filled === 0) filled = 1;
  return `${"█".repeat(filled)}${"░".repeat(width - filled)}`;
}

function isOpenAIProvider(providerID?: string): boolean {
  if (!providerID) return false;
  return providerID.toLowerCase().includes("openai");
}

function sessionUsesOpenAI(api: TuiPluginApi, sessionID: string): boolean {
  if (!sessionID) return true;
  const messages = api.state.session.messages(sessionID);
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    const providerID = msg.role === "assistant" ? msg.providerID : msg.model?.providerID;
    if (providerID) return isOpenAIProvider(providerID);
  }
  const configured = api.state.config.model;
  if (typeof configured === "string") return configured.startsWith("openai/");
  return true;
}

function currentSessionID(api: TuiPluginApi, props: { session_id?: string } | Record<string, unknown>): string {
  const p = props as any;
  const fromProps = p.session_id ?? p.sessionID;
  if (typeof fromProps === "string" && fromProps) return fromProps;
  const current = api.route.current;
  if (current.name === "session" && typeof current.params.sessionID === "string") return current.params.sessionID;
  const fromRoute = current.params?.sessionID;
  return typeof fromRoute === "string" ? fromRoute : "";
}

function configuredModel(api: TuiPluginApi): { providerID: string; modelID: string } | null {
  const configured = api.state.config.model;
  if (typeof configured !== "string") return null;
  const slash = configured.indexOf("/");
  if (slash <= 0) return null;
  return { providerID: configured.slice(0, slash), modelID: configured.slice(slash + 1) };
}

function latestModel(api: TuiPluginApi, sessionID: string): { providerID: string; modelID: string } | null {
  const messages = api.state.session.messages(sessionID);
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.role === "assistant") return { providerID: msg.providerID, modelID: msg.modelID };
    if (msg.model?.providerID && msg.model?.modelID) return msg.model;
  }
  return configuredModel(api);
}

function contextLimit(api: TuiPluginApi, model: { providerID: string; modelID: string } | null): number | null {
  if (!model) return null;
  const config = api.state.config as any;
  const exact = config.provider?.[model.providerID]?.models?.[model.modelID]?.limit?.context;
  if (typeof exact === "number" && exact > 0) return exact;

  for (const provider of Object.values(config.provider ?? {}) as any[]) {
    const limit = provider?.models?.[model.modelID]?.limit?.context;
    if (typeof limit === "number" && limit > 0) return limit;
  }

  if (model.modelID.startsWith("gpt-5.5")) return 1_050_000;
  if (model.modelID.startsWith("gpt-5.4") || model.modelID.startsWith("gpt-5.1")) return 400_000;
  return null;
}

function latestContextSampleFromState(api: TuiPluginApi, sessionID: string): ContextSample | null {
  const messages = api.state.session.messages(sessionID);
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.role !== "assistant") continue;
    const tokens =
      typeof msg.tokens.total === "number"
        ? msg.tokens.total
        : msg.tokens.input + msg.tokens.cache.read + msg.tokens.cache.write;
    if (tokens > 0) return { tokens, providerID: msg.providerID, modelID: msg.modelID };
  }
  return null;
}

let db: Database | null | undefined;

function opencodeDb(): Database | null {
  if (db !== undefined) return db;
  try {
    db = new Database(OPENCODE_DB, { readonly: true });
  } catch {
    db = null;
  }
  return db;
}

function latestContextSampleFromDb(sessionID: string): ContextSample | null {
  const database = opencodeDb();
  if (!database) return null;
  const rows = sessionID
    ? database.query("select data from message where session_id = ? order by time_created desc limit 30").all(sessionID)
    : database.query("select data from message order by time_created desc limit 30").all();
  for (const row of rows as Array<{ data: string }>) {
    try {
      const msg = JSON.parse(row.data);
      if (msg?.role !== "assistant" || !msg?.tokens) continue;
      const tokens =
        typeof msg.tokens.total === "number"
          ? msg.tokens.total
          : (msg.tokens.input ?? 0) + (msg.tokens.cache?.read ?? 0) + (msg.tokens.cache?.write ?? 0);
      if (tokens > 0) return { tokens, providerID: msg.providerID, modelID: msg.modelID };
    } catch {
      continue;
    }
  }
  return null;
}

function contextUsage(api: TuiPluginApi, sessionID: string): ContextUsage | null {
  const sample = latestContextSampleFromState(api, sessionID) ?? latestContextSampleFromDb(sessionID);
  if (!sample) return null;
  const model = sample.providerID && sample.modelID ? { providerID: sample.providerID, modelID: sample.modelID } : latestModel(api, sessionID);
  const limit = contextLimit(api, model);
  if (!limit) return null;
  const percent = Math.max(0, Math.min(100, Math.round((sample.tokens / limit) * 100)));
  return { tokens: sample.tokens, percent };
}

function formatTokens(tokens: number): string {
  if (tokens >= 1_000_000) return `${(tokens / 1_000_000).toFixed(1)}m`;
  if (tokens >= 10_000) return `${Math.round(tokens / 1000)}k`;
  if (tokens >= 1000) return `${(tokens / 1000).toFixed(1)}k`;
  return String(tokens);
}

function formatContext(u: ContextUsage | null): string {
  if (!u) return "";
  return `ctx ${bar(u.percent)} ${u.percent}% (${formatTokens(u.tokens)})`;
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

function statusColor(s: Status, theme: Theme): ThemeColor {
  if (s.type === "loading") return theme.textMuted;
  if (s.type !== "ready") return theme.warning;
  const min = Math.min(...s.limits.map((l) => l.leftPercent));
  if (min <= 10) return theme.error;
  if (min <= 25) return theme.warning;
  return theme.success;
}

function contextColor(context: ContextUsage | null, theme: Theme): ThemeColor {
  if (!context) return theme.textMuted;
  if (context.percent >= 90) return theme.error;
  if (context.percent >= 70) return theme.warning;
  return theme.success;
}

function limitColor(limit: Limit, theme: Theme): ThemeColor {
  if (limit.leftPercent <= 10) return theme.error;
  if (limit.leftPercent <= 25) return theme.warning;
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
      session_prompt_right: (props) => {
        const root = solid.createElement("box");
        solid.spread(root, { flexDirection: "row", width: "auto", height: 1 }, false);

        function textNode(content: () => string, fg: () => ThemeColor) {
          const node = solid.createElement("text");
          solid.spread(
            node,
            {
              get content() {
                return content();
              },
              get fg() {
                return fg();
              },
              selectable: false,
              truncate: true,
              wrapMode: "none",
            },
            false,
          );
          root.add(node);
        }

        function currentContext() {
          return contextUsage(api, currentSessionID(api, props));
        }

        function statusText(index: number) {
          const s = status();
          if (s.type === "loading") return "";
          if (s.type === "missing" && index === 0) return "codex: no auth";
          if (s.type === "error" && index === 0) return `codex: ${s.message}`;
          if (s.type !== "ready") return "";
          const limit = s.limits[index];
          if (!limit) return "";
          return `${limit.label} ${bar(limit.leftPercent)} ${limit.leftPercent}% left`;
        }

        function hasContext() {
          return Boolean(formatContext(currentContext()));
        }

        function showCodex() {
          return sessionUsesOpenAI(api, currentSessionID(api, props));
        }

        textNode(
          () => formatContext(currentContext()),
          () => contextColor(currentContext(), api.theme.current),
        );
        textNode(
          () => (hasContext() && showCodex() && statusText(0) ? " · " : ""),
          () => api.theme.current.textMuted,
        );
        textNode(
          () => (showCodex() ? statusText(0) : ""),
          () => {
            const s = status();
            if (s.type !== "ready") return statusColor(s, api.theme.current);
            return limitColor(s.limits[0], api.theme.current);
          },
        );
        textNode(
          () => (showCodex() && statusText(0) && statusText(1) ? " · " : ""),
          () => api.theme.current.textMuted,
        );
        textNode(
          () => (showCodex() ? statusText(1) : ""),
          () => {
            const s = status();
            return s.type === "ready" && s.limits[1]
              ? limitColor(s.limits[1], api.theme.current)
              : api.theme.current.textMuted;
          },
        );

        return root;
      },
    },
  });
};

const plugin: TuiPluginModule & { id: string } = {
  id: "codex-status",
  tui,
};

export default plugin;
