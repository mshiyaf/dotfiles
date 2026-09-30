#!/usr/bin/env python3
"""Coding-agent usage, accounts, and live sessions as one JSON document.

  usage.py collect '<json config>'   print the snapshot
  usage.py focus <herdr-pane-id>     focus an agent pane and raise its terminal window

Config keys: cache_dir, force, api_min_age, codex_home, account_home.

Credentials are read locally and sent only to the vendor that issued them.
Inactive saved profiles (from `ai-account`) are refreshed here when expired;
the active login belongs to the running CLI and is never refreshed or rewritten.
Standard library only, so it runs under the system python3.
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path

HOME = Path.home()
HTTP_TIMEOUT = 10
FIVE_HOURS = 5 * 3600
SEVEN_DAYS = 7 * 86400
REFRESH_BACKOFF = 3600

CLAUDE_USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
CLAUDE_TOKEN_URL = "https://platform.claude.com/v1/oauth/token"
CLAUDE_CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage"
CODEX_RESETS_URL = "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits"
CODEX_TOKEN_URL = "https://auth.openai.com/oauth/token"
CODEX_CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann"
COMMANDCODE_API = "https://api.commandcode.ai"

# The shell's PATH lacks user tool directories.
os.environ["PATH"] = os.pathsep.join(
    [str(HOME / ".local/bin"), str(HOME / ".local/share/mise/shims"), os.environ.get("PATH", "/usr/bin")]
)


def now() -> float:
    return time.time()


def local_midnight() -> float:
    return datetime.now().astimezone().replace(hour=0, minute=0, second=0, microsecond=0).timestamp()


def parse_time(value) -> float | None:
    """ISO strings, epoch seconds, or epoch milliseconds."""
    if isinstance(value, (int, float)) and value > 0:
        return value / 1000 if value > 1e12 else float(value)
    if isinstance(value, str) and value:
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return None
    return None


def read_json(path: Path):
    try:
        with path.open() as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return None


def write_json(path: Path, data, private: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f"{path.name}.tmp-{os.getpid()}")
    with open(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600 if private else 0o644), "w") as fh:
        json.dump(data, fh, indent=2 if private else None)
    os.replace(tmp, path)


def http(url: str, headers: dict, body: bytes | None = None) -> tuple[int, object]:
    req = urllib.request.Request(url, data=body, headers=headers, method="POST" if body is not None else "GET")
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as resp:
            return resp.status, json.loads(resp.read().decode() or "null")
    except urllib.error.HTTPError as err:
        try:
            return err.code, json.loads(err.read().decode() or "null")
        except (OSError, ValueError):
            return err.code, None
    except (urllib.error.URLError, TimeoutError, OSError, ValueError):
        return 0, None


def status_for(code: int) -> str:
    if code in (401, 403):
        return "signin"
    if code == 429:
        return "limited"
    return "offline" if code == 0 else "error"


def jwt_claims(token: str) -> dict:
    try:
        payload = token.split(".")[1]
        return json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
    except (IndexError, ValueError):
        return {}


def refresh_error(code: int, data) -> str:
    err = data.get("error") if isinstance(data, dict) else None
    if isinstance(err, dict):
        err = err.get("type") or err.get("code") or err.get("message")
    return f"{err or 'refresh failed'} ({code})" if code else "offline"


def fingerprint(secret: str) -> str:
    return hashlib.sha256(secret.encode()).hexdigest()[:16]


def window(wid: str, label: str, used, resets_at, duration) -> dict | None:
    try:
        used = float(used)
    except (TypeError, ValueError):
        return None
    return {"id": wid, "label": label, "used": max(0.0, min(100.0, used)), "resetsAt": resets_at, "duration": duration}


class Cache:
    """Small JSON store for API results and refresh backoff; never holds secrets."""

    def __init__(self, directory: Path):
        self.path = directory / "usage-cache.json"
        data = read_json(self.path)
        self.data = data if isinstance(data, dict) else {}

    def fresh(self, key: str, min_age: float):
        entry = self.data.get(key)
        if isinstance(entry, dict) and now() - float(entry.get("at") or 0) < min_age:
            return entry.get("value")
        return None

    def last(self, key: str):
        entry = self.data.get(key)
        return entry.get("value") if isinstance(entry, dict) else None

    def put(self, key: str, value) -> None:
        self.data[key] = {"at": now(), "value": value}

    def save(self) -> None:
        try:
            write_json(self.path, self.data)
        except OSError:
            pass


# ── Saved profiles (ai-account store) ────────────────────────────────────────


@contextmanager
def account_lock(account_home: Path, timeout: float = 15.0):
    """Same mkdir lock ai-account takes around credential writes."""
    lock = account_home / ".lock"
    deadline = now() + timeout
    while True:
        try:
            lock.mkdir()
            break
        except FileExistsError:
            try:
                if now() - lock.stat().st_mtime > 30:
                    lock.rmdir()
                    continue
            except OSError:
                continue
            if now() > deadline:
                raise TimeoutError("account lock busy")
            time.sleep(0.1)
    try:
        yield
    finally:
        try:
            lock.rmdir()
        except OSError:
            pass


def saved_profiles(account_home: Path, provider: str) -> tuple[list[str], str]:
    directory = account_home / provider
    try:
        names = sorted(p.stem for p in directory.glob("*.json"))
    except OSError:
        names = []
    try:
        active = (directory / ".active").read_text().strip()
    except OSError:
        active = ""
    return names, active


def codex_identity(creds) -> str:
    tokens = creds.get("tokens") if isinstance(creds, dict) else None
    if not isinstance(tokens, dict):
        return ""
    claims = jwt_claims(str(tokens.get("access_token") or ""))
    return str(tokens.get("account_id") or claims.get("https://api.openai.com/auth", {}).get("chatgpt_account_id") or "")


def account_list(account_home: Path, provider: str, live_file: Path) -> list[dict]:
    """Each account: profile name, whether it is the live login, and which file holds it."""
    names, active = saved_profiles(account_home, provider)
    if not names:
        return [{"profile": "", "label": "", "active": True, "file": live_file}]
    if provider == "codex":
        # The ChatGPT app can switch accounts without ai-account; trust the live login's identity.
        live_id = codex_identity(read_json(live_file))
        ids = {name: codex_identity(read_json(account_home / provider / f"{name}.json")) for name in names}
        matches = [name for name, ident in ids.items() if live_id and ident == live_id]
        active = matches[0] if matches else ("" if live_id else active)
    accounts = []
    for name in names:
        is_active = name == active and live_file.exists()
        accounts.append({
            "profile": name,
            "label": name.replace("-", " ").replace("_", " ").title(),
            "active": is_active,
            "file": live_file if is_active else account_home / provider / f"{name}.json",
        })
    if live_file.exists() and not any(a["active"] for a in accounts):
        accounts.insert(0, {"profile": "", "label": "Unsaved login", "active": True, "file": live_file})
    return accounts


def refresh_profile(ctx, provider: str, path: Path, refresher) -> bool:
    """Refresh an inactive profile's tokens under the account lock, with failure backoff."""
    creds = read_json(path)
    key = f"refresh-fail:{provider}:{path.name}"
    token = refresher.refresh_token(creds)
    if not token:
        return False
    failed = ctx.cache.last(key)
    if isinstance(failed, dict) and failed.get("fp") == fingerprint(token) and now() - failed.get("at", 0) < REFRESH_BACKOFF:
        return False
    try:
        with account_lock(ctx.account_home):
            creds = read_json(path)  # re-read: a switch may have happened meanwhile
            token = refresher.refresh_token(creds)
            if not token or not path.exists():
                return False
            updated, reason = refresher.refresh(creds, token)
            if updated is None:
                ctx.cache.put(key, {"fp": fingerprint(token), "at": now(), "reason": reason})
                return False
            write_json(path, updated, private=True)
            return True
    except TimeoutError:
        return False


# ── Claude Code ──────────────────────────────────────────────────────────────


class ClaudeRefresher:
    @staticmethod
    def refresh_token(creds):
        oauth = creds.get("claudeAiOauth") if isinstance(creds, dict) else None
        return oauth.get("refreshToken") if isinstance(oauth, dict) else None

    @staticmethod
    def refresh(creds, token):
        body = json.dumps({"grant_type": "refresh_token", "refresh_token": token, "client_id": CLAUDE_CLIENT_ID}).encode()
        code, data = http(CLAUDE_TOKEN_URL, {"Content-Type": "application/json", "User-Agent": "noctalia-agents"}, body)
        if code != 200 or not isinstance(data, dict) or not data.get("access_token"):
            return None, refresh_error(code, data)
        oauth = dict(creds["claudeAiOauth"])
        oauth["accessToken"] = data["access_token"]
        oauth["refreshToken"] = data.get("refresh_token") or token
        oauth["expiresAt"] = int((now() + float(data.get("expires_in") or 28800)) * 1000)
        return {**creds, "claudeAiOauth": oauth}, ""


def claude_plan(oauth: dict) -> str:
    tier = str(oauth.get("rateLimitTier") or "")
    for mult in ("20x", "5x"):
        if tier.endswith(mult):
            return f"Max {mult}"
    return str(oauth.get("subscriptionType") or "").capitalize()


def claude_windows(data: dict) -> list:
    out = []
    for key, wid, label, duration in (
        ("five_hour", "session", "Session", FIVE_HOURS),
        ("seven_day", "weekly", "Weekly", SEVEN_DAYS),
        ("seven_day_opus", "weekly_opus", "Opus", SEVEN_DAYS),
        ("seven_day_sonnet", "weekly_sonnet", "Sonnet", SEVEN_DAYS),
    ):
        section = data.get(key)
        if isinstance(section, dict):
            w = window(wid, label, section.get("utilization"), parse_time(section.get("resets_at")), duration)
            # Model-scoped weeks only matter once touched.
            if w and (wid in ("session", "weekly") or w["used"] > 0):
                out.append(w)
    return out


def claude_account(ctx, acct: dict) -> dict:
    result = {"profile": acct["profile"], "label": acct["label"], "active": acct["active"],
              "plan": "", "status": "ok", "windows": [], "fetchedAt": None}
    cache_key = f"claude:{acct['profile'] or 'default'}"
    creds = read_json(acct["file"])
    oauth = creds.get("claudeAiOauth") if isinstance(creds, dict) else None
    if not isinstance(oauth, dict) or not oauth.get("accessToken"):
        result["status"] = "missing"
        return result
    result["plan"] = claude_plan(oauth)

    def from_cache(status: str) -> dict:
        cached = ctx.cache.last(cache_key)
        if isinstance(cached, dict):
            result["windows"], result["fetchedAt"] = cached.get("windows", []), cached.get("fetchedAt")
        result["status"] = status
        return result

    if not ctx.force and ctx.cache.fresh(cache_key, ctx.min_age) is not None:
        return from_cache("ok")

    expired = float(oauth.get("expiresAt") or 0) / 1000 < now() + 60
    if expired:
        if acct["active"]:
            return from_cache("expired")
        if not refresh_profile(ctx, "claude", acct["file"], ClaudeRefresher):
            return from_cache("signin")
        oauth = read_json(acct["file"])["claudeAiOauth"]

    code, data = http(CLAUDE_USAGE_URL, {
        "Authorization": f"Bearer {oauth['accessToken']}",
        "anthropic-beta": "oauth-2025-04-20",
        "Accept": "application/json",
        "User-Agent": "noctalia-agents",
    })
    if code == 200 and isinstance(data, dict):
        result["windows"], result["fetchedAt"] = claude_windows(data), now()
        ctx.cache.put(cache_key, {"windows": result["windows"], "fetchedAt": result["fetchedAt"]})
        return result
    return from_cache(status_for(code))


def claude_tokens_today(config_dir: Path, midnight: float, file_cache: dict) -> int:
    projects = config_dir / "projects"
    if not projects.is_dir():
        return 0
    total, seen = 0, set()
    for path in projects.rglob("*.jsonl"):
        try:
            st = path.stat()
        except OSError:
            continue
        if st.st_mtime < midnight:
            continue
        key = f"claude:{path}"
        hit = file_cache.get(key)
        if hit and hit["size"] == st.st_size and hit["mtime"] == st.st_mtime and hit["midnight"] == midnight:
            total += hit["tokens"]
            seen.update(hit["ids"])
            continue
        tokens, ids = 0, []
        try:
            with path.open(errors="replace") as fh:
                for line in fh:
                    if '"usage"' not in line or '"assistant"' not in line:
                        continue
                    try:
                        rec = json.loads(line)
                    except ValueError:
                        continue
                    ts = parse_time(rec.get("timestamp"))
                    msg = rec.get("message") if isinstance(rec.get("message"), dict) else {}
                    usage = msg.get("usage")
                    if ts is None or ts < midnight or not isinstance(usage, dict):
                        continue
                    # Streaming writes one line per content block with the same usage.
                    uid = f"{msg.get('id')}:{rec.get('requestId')}"
                    if uid in seen:
                        continue
                    seen.add(uid)
                    ids.append(uid)
                    tokens += sum(int(usage.get(k) or 0) for k in (
                        "input_tokens", "output_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
        except OSError:
            continue
        file_cache[key] = {"size": st.st_size, "mtime": st.st_mtime, "midnight": midnight, "tokens": tokens, "ids": ids}
        total += tokens
    return total


# ── Codex ────────────────────────────────────────────────────────────────────


class CodexRefresher:
    @staticmethod
    def refresh_token(creds):
        tokens = creds.get("tokens") if isinstance(creds, dict) else None
        return tokens.get("refresh_token") if isinstance(tokens, dict) else None

    @staticmethod
    def refresh(creds, token):
        body = urllib.parse.urlencode({"grant_type": "refresh_token", "refresh_token": token, "client_id": CODEX_CLIENT_ID}).encode()
        code, data = http(CODEX_TOKEN_URL, {"Content-Type": "application/x-www-form-urlencoded"}, body)
        if code != 200 or not isinstance(data, dict) or not data.get("access_token"):
            return None, refresh_error(code, data)
        tokens = dict(creds["tokens"])
        tokens["access_token"] = data["access_token"]
        tokens["refresh_token"] = data.get("refresh_token") or token
        if data.get("id_token"):
            tokens["id_token"] = data["id_token"]
        return {**creds, "tokens": tokens, "last_refresh": datetime.now().astimezone().isoformat()}, ""


def codex_email(tokens) -> str:
    """Login email from the ID token; used to match Amp's linked ChatGPT subscriptions."""
    if not isinstance(tokens, dict):
        return ""
    claims = jwt_claims(str(tokens.get("id_token") or ""))
    email = claims.get("email") or claims.get("https://api.openai.com/profile", {}).get("email") or ""
    return str(email).lower()


def codex_window(wid: str, section) -> dict | None:
    if not isinstance(section, dict):
        return None
    resets = parse_time(section.get("reset_at") or section.get("resets_at"))
    if resets is None and section.get("reset_after_seconds") is not None:
        resets = now() + float(section["reset_after_seconds"])
    duration = section.get("limit_window_seconds")
    if duration is None and section.get("window_minutes") is not None:
        duration = float(section["window_minutes"]) * 60
    label = "Weekly" if duration and float(duration) >= 86400 else "Session"
    return window(wid, label, section.get("used_percent"), resets, duration)


def codex_windows(rate_limit: dict) -> list:
    out = []
    for wid, keys in (("primary", ("primary_window", "primary")), ("secondary", ("secondary_window", "secondary"))):
        section = next((rate_limit.get(k) for k in keys if isinstance(rate_limit.get(k), dict)), None)
        w = codex_window(wid, section)
        if w:
            out.append(w)
    return out


def codex_account(ctx, acct: dict, log_limits: dict | None) -> dict:
    result = {"profile": acct["profile"], "label": acct["label"], "active": acct["active"], "plan": "", "email": "",
              "status": "ok", "source": "api", "windows": [], "credits": None, "resets": None, "fetchedAt": None}
    cache_key = f"codex:{acct['profile'] or 'default'}"
    cached = ctx.cache.fresh(cache_key, ctx.min_age) if not ctx.force else None
    if isinstance(cached, dict):
        result.update(cached)
        result["email"] = codex_email((read_json(acct["file"]) or {}).get("tokens"))
        return result

    creds = read_json(acct["file"])
    tokens = creds.get("tokens") if isinstance(creds, dict) else None
    result["email"] = codex_email(tokens)
    status = "missing"
    if isinstance(tokens, dict) and tokens.get("access_token"):
        exp = jwt_claims(tokens["access_token"]).get("exp") or 0
        if exp and exp < now() + 60 and not acct["active"] and refresh_profile(ctx, "codex", acct["file"], CodexRefresher):
            tokens = read_json(acct["file"])["tokens"]
        account_id = tokens.get("account_id") or jwt_claims(tokens["access_token"]).get(
            "https://api.openai.com/auth", {}).get("chatgpt_account_id")
        headers = {"Authorization": f"Bearer {tokens['access_token']}", "Accept": "application/json",
                   "User-Agent": "codex_cli_rs", "originator": "codex_cli_rs"}
        if account_id:
            headers["ChatGPT-Account-Id"] = str(account_id)
        code, data = http(CODEX_USAGE_URL, headers)
        if code == 200 and isinstance(data, dict):
            result["plan"] = str(data.get("plan_type") or "")
            result["windows"] = codex_windows(data.get("rate_limit") or {})
            credits = data.get("credits")
            result["credits"] = credits if isinstance(credits, dict) else None
            code_r, resets = http(CODEX_RESETS_URL, headers)
            if code_r == 200 and isinstance(resets, dict):
                available = [c for c in resets.get("credits") or [] if c.get("status") == "available"]
                expiries = sorted(t for t in (parse_time(c.get("expires_at")) for c in available) if t)
                result["resets"] = {"available": int(resets.get("available_count", len(available)) or 0),
                                    "nextExpiresAt": expiries[0] if expiries else None}
            result["fetchedAt"] = now()
            ctx.cache.put(cache_key, {k: result[k] for k in ("plan", "windows", "credits", "resets", "fetchedAt", "source")})
            return result
        status = status_for(code)

    # The live account can fall back to the limits Codex logs after every turn.
    if acct["active"] and isinstance(log_limits, dict):
        result.update({"plan": str(log_limits.get("plan_type") or ""), "windows": codex_windows(log_limits),
                       "source": "logs", "status": "ok"})
        return result
    last = ctx.cache.last(cache_key)
    if isinstance(last, dict):
        result.update(last)
    result["status"] = status
    return result


def codex_scan_sessions(codex_home: Path, midnight: float, file_cache: dict) -> tuple[int, dict | None]:
    """Today's Codex tokens and the newest rate_limits record in the session logs."""
    sessions = codex_home / "sessions"
    if not sessions.is_dir():
        return 0, None
    total, latest = 0, None
    # Sessions live under their start date; a week back covers long-running ones.
    for path in sessions.glob("*/*/*/*.jsonl"):
        try:
            st = path.stat()
        except OSError:
            continue
        if st.st_mtime < midnight - SEVEN_DAYS:
            continue
        key = f"codex:{path}"
        hit = file_cache.get(key)
        if hit and hit["size"] == st.st_size and hit["mtime"] == st.st_mtime and hit["midnight"] == midnight:
            tokens, limits = hit["tokens"], hit.get("limits")
        else:
            tokens, limits, prev = 0, None, 0
            try:
                with path.open(errors="replace") as fh:
                    for line in fh:
                        if '"token_count"' not in line:
                            continue
                        try:
                            rec = json.loads(line)
                        except ValueError:
                            continue
                        payload = rec.get("payload") or {}
                        ts = parse_time(rec.get("timestamp"))
                        if isinstance(payload.get("rate_limits"), dict) and ts:
                            limits = {"ts": ts, "data": payload["rate_limits"]}
                        info = payload.get("info")
                        if not isinstance(info, dict):
                            continue
                        cur = int((info.get("total_token_usage") or {}).get("total_tokens") or 0)
                        # Totals are cumulative per session; count only today's growth.
                        if ts and ts >= midnight and cur > prev:
                            tokens += cur - prev
                        prev = max(prev, cur)
            except OSError:
                continue
            file_cache[key] = {"size": st.st_size, "mtime": st.st_mtime, "midnight": midnight, "tokens": tokens, "limits": limits}
        total += tokens
        if limits and (latest is None or limits["ts"] > latest[0]):
            latest = (limits["ts"], limits["data"])
    return total, (latest[1] if latest else None)


# ── Amp ──────────────────────────────────────────────────────────────────────

MONEY = r"(-?\$?-?[\d,]+(?:\.\d+)?)"


def money(text: str) -> float:
    return float(text.replace("$", "").replace(",", ""))


def amp_usage(ctx) -> dict | None:
    if not shutil.which("amp"):
        return None
    cached = ctx.cache.fresh("amp", ctx.min_age) if not ctx.force else None
    if isinstance(cached, dict):
        return cached
    result = {"status": "ok", "plan": "", "windows": [], "balance": None, "providers": [], "fetchedAt": None}
    try:
        out = subprocess.run(["amp", "usage"], capture_output=True, text=True, timeout=25).stdout
    except (OSError, subprocess.TimeoutExpired):
        out = ""
    plain = re.sub(r"\*\*", "", out)
    tier = re.search(r"Amp ([\w -]+?) Tier", plain)
    agent = re.search(rf"agent usage {MONEY} of {MONEY} remaining", plain)
    period = re.search(r"period (\d{4}-\d{2}-\d{2}) to (\d{4}-\d{2}-\d{2})", plain)
    credits = re.search(rf"Individual credits:\s*{MONEY} remaining", plain)
    if tier:
        result["plan"] = tier.group(1).strip()
    if agent:
        remaining, total = money(agent.group(1)), money(agent.group(2))
        start = parse_time(period.group(1)) if period else None
        end = parse_time(period.group(2)) if period else None
        used = 100 * (1 - remaining / total) if total > 0 else 0
        result["windows"].append(window("period", "Monthly", used, end, (end - start) if start and end else None))
    if credits:
        result["balance"] = money(credits.group(1))
    if not agent and result["balance"] is None:
        result["status"] = "signin" if "log in" in out.lower() or "not signed" in out.lower() else "error"
        return ctx.cache.last("amp") or result
    result["providers"] = amp_providers()
    result["fetchedAt"] = now()
    ctx.cache.put("amp", result)
    return result


def amp_providers() -> list:
    """Linked model providers (bring-your-own subscriptions and keys), in routing order."""
    try:
        out = subprocess.run(["amp", "config", "model-providers", "list", "--json"], capture_output=True, text=True, timeout=25).stdout
        rows = json.loads(out)
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return []
    providers = []
    for row in rows if isinstance(rows, list) else []:
        if not isinstance(row, dict) or not row.get("id"):
            continue
        config = row.get("config") if isinstance(row.get("config"), dict) else {}
        providers.append({
            "id": str(row["id"]),
            "name": str(row.get("name") or ""),
            "type": str(row.get("type") or "").removeprefix("model_provider_"),
            "active": row.get("active") is True,
            "priority": row.get("priority"),
            # Older links lack accountEmail but are named "<email>'s subscription".
            "email": str(config.get("accountEmail") or next(iter(re.findall(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+", str(row.get("name") or ""))), "")).lower(),
        })
    providers.sort(key=lambda p: (p["priority"] if isinstance(p["priority"], int) else 99))
    return providers


# ── Command Code ─────────────────────────────────────────────────────────────


def commandcode_usage(ctx) -> dict | None:
    auth = read_json(HOME / ".commandcode" / "auth.json")
    key = os.environ.get("COMMANDCODE_API_KEY") or (auth.get("apiKey") if isinstance(auth, dict) else None)
    if not key:
        return None
    cached = ctx.cache.fresh("commandcode", ctx.min_age) if not ctx.force else None
    if isinstance(cached, dict):
        return cached
    headers = {"Authorization": f"Bearer {key}", "Accept": "application/json", "User-Agent": "noctalia-agents"}
    result = {"status": "ok", "plan": "", "windows": [], "balance": None, "periodEndsAt": None, "fetchedAt": None}
    code, who = http(f"{COMMANDCODE_API}/alpha/whoami?limits=1", headers)
    if code != 200 or not isinstance(who, dict):
        result["status"] = status_for(code)
        return ctx.cache.last("commandcode") or result
    org = (who.get("org") or {}).get("id")
    query = f"?orgId={urllib.parse.quote(str(org))}" if org else ""
    _, billing = http(f"{COMMANDCODE_API}/alpha/billing/credits{query}", headers)
    _, sub = http(f"{COMMANDCODE_API}/alpha/billing/subscriptions{query}", headers)
    billing = billing if isinstance(billing, dict) else {}
    limits = billing.get("windowLimits") if isinstance(billing.get("windowLimits"), dict) else {}
    for wid, label, duration in (("fiveHour", "Session", FIVE_HOURS), ("weekly", "Weekly", SEVEN_DAYS)):
        section = limits.get(wid)
        if isinstance(section, dict) and float(section.get("cap") or 0) > 0:
            used = 100 * float(section.get("used") or 0) / float(section["cap"])
            # resetAt is 0 until the window has been used.
            w = window(wid, label, used, parse_time(section.get("resetAt")), duration)
            if w:
                result["windows"].append(w)
    credits = billing.get("credits")
    if isinstance(credits, dict):
        amounts = [credits.get(k) for k in ("monthlyCredits", "purchasedCredits", "freeCredits")]
        result["balance"] = sum(v for v in amounts if isinstance(v, (int, float)))
    data = (sub or {}).get("data") if isinstance(sub, dict) else None
    data = data if isinstance(data, dict) else {}
    result["plan"] = str(data.get("planId") or "").replace("_", " ").replace("-", " ").title()
    result["periodEndsAt"] = parse_time(data.get("currentPeriodEnd"))
    result["fetchedAt"] = now()
    ctx.cache.put("commandcode", result)
    return result


# ── Live sessions (herdr) ────────────────────────────────────────────────────


def herdr_sessions() -> list:
    if not shutil.which("herdr"):
        return []
    try:
        out = subprocess.run(["herdr", "agent", "list"], capture_output=True, text=True, timeout=5).stdout
        agents = json.loads(out)["result"]["agents"]
    except (OSError, subprocess.TimeoutExpired, ValueError, KeyError, TypeError):
        return []
    sessions = []
    for a in agents:
        cwd = a.get("foreground_cwd") or a.get("cwd") or ""
        sessions.append({
            "agent": a.get("agent") or "",
            "title": a.get("terminal_title_stripped") or "",
            "project": Path(cwd).name if cwd else "",
            "cwd": cwd.replace(str(HOME), "~", 1),
            "status": a.get("agent_status") or "",
            "paneId": a.get("pane_id") or "",
            "focused": a.get("focused") is True,
        })
    order = {"working": 0, "blocked": 1, "waiting": 1, "idle": 2}
    sessions.sort(key=lambda s: (order.get(s["status"], 3), s["project"]))
    return sessions


def focus(pane_id: str) -> int:
    subprocess.run(["herdr", "agent", "focus", pane_id], capture_output=True, timeout=5)
    # Raise the terminal window that hosts a herdr client.
    try:
        windows = json.loads(subprocess.run(["niri", "msg", "-j", "windows"], capture_output=True, text=True, timeout=5).stdout)
    except (OSError, subprocess.TimeoutExpired, ValueError):
        return 0
    by_pid = {w.get("pid"): w.get("id") for w in windows}
    for proc in Path("/proc").iterdir():
        if not proc.name.isdigit():
            continue
        try:
            argv = (proc / "cmdline").read_bytes().split(b"\0")
        except OSError:
            continue
        if not argv or Path(argv[0].decode(errors="replace")).name != "herdr" or b"server" in argv[1:2]:
            continue
        pid = int(proc.name)
        for _ in range(8):  # walk up to the terminal emulator
            if pid in by_pid:
                subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(by_pid[pid])], capture_output=True, timeout=5)
                return 0
            try:
                pid = int((Path("/proc") / str(pid) / "stat").read_text().rsplit(")", 1)[1].split()[1])
            except (OSError, IndexError, ValueError):
                break
    return 0


# ── Entry point ──────────────────────────────────────────────────────────────


class Context:
    def __init__(self, cfg: dict):
        cache_dir = Path(os.path.expanduser(cfg.get("cache_dir") or "~/.cache/noctalia-agents"))
        cache_dir.mkdir(parents=True, exist_ok=True)
        self.cache_dir = cache_dir
        self.cache = Cache(cache_dir)
        self.force = bool(cfg.get("force"))
        self.min_age = int(cfg.get("api_min_age") or 60)
        self.codex_home = Path(os.path.expanduser(cfg.get("codex_home") or "~/.codex"))
        self.account_home = Path(os.path.expanduser(cfg.get("account_home") or "~/.local/share/ai-accounts"))


def collect(cfg: dict) -> dict:
    ctx = Context(cfg)
    midnight = local_midnight()
    file_cache_path = ctx.cache_dir / "token-files.json"
    file_cache = read_json(file_cache_path)
    file_cache = file_cache if isinstance(file_cache, dict) else {}

    claude_accts = account_list(ctx.account_home, "claude", HOME / ".claude" / ".credentials.json")
    codex_accts = account_list(ctx.account_home, "codex", ctx.codex_home / "auth.json")
    claude_tokens = claude_tokens_today(HOME / ".claude", midnight, file_cache)
    codex_tokens, log_limits = codex_scan_sessions(ctx.codex_home, midnight, file_cache)

    # Network calls are independent; run them side by side.
    with ThreadPoolExecutor(max_workers=6) as pool:
        claude_f = [pool.submit(claude_account, ctx, a) for a in claude_accts]
        codex_f = [pool.submit(codex_account, ctx, a, log_limits) for a in codex_accts] if ctx.codex_home.is_dir() else []
        amp_f = pool.submit(amp_usage, ctx)
        cc_f = pool.submit(commandcode_usage, ctx)
        sessions_f = pool.submit(herdr_sessions)
        snapshot = {
            "generatedAt": now(),
            "tokensToday": {"total": claude_tokens + codex_tokens, "claude": claude_tokens, "codex": codex_tokens},
            "claude": {"managed": any(a["profile"] for a in claude_accts), "accounts": [f.result() for f in claude_f]},
            "codex": {"installed": ctx.codex_home.is_dir(), "managed": any(a["profile"] for a in codex_accts),
                      "accounts": [f.result() for f in codex_f]},
            "amp": amp_f.result(),
            "commandcode": cc_f.result(),
            "sessions": sessions_f.result(),
        }

    try:
        write_json(file_cache_path, {k: v for k, v in file_cache.items() if v.get("midnight") == midnight})
    except OSError:
        pass
    ctx.cache.save()
    return snapshot


def main() -> int:
    command = sys.argv[1] if len(sys.argv) > 1 else "collect"
    if command == "focus" and len(sys.argv) > 2:
        return focus(sys.argv[2])
    try:
        cfg = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    except ValueError:
        cfg = {}
    json.dump(collect(cfg), sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
