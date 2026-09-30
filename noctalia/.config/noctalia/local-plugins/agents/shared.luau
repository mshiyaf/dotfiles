--!nonstrict
-- Helpers shared by the service, bar widget, and panel.

local M = {}

M.STATE_KEY = "agents_snapshot"
M.COMMAND_KEY = "agents_command"
M.PANEL_ID = "mshiyaf/agents:panel"

M.TRACK_COLOR = "on_surface/0.14"

M.STATUS_TEXT = {
  signin = "Sign-in required",
  expired = "Token expired",
  missing = "Not signed in",
  limited = "Rate limited",
  offline = "Offline",
  error = "Unavailable",
}

-- Agents with a brand mark; single-color marks ship light and dark variants.
M.AGENTS = {
  claude = { name = "Claude Code", icon = "assets/claude.svg" },
  codex = { name = "Codex", light = "assets/codex-light.svg", dark = "assets/codex-dark.svg" },
  amp = { name = "Amp", icon = "assets/amp.svg" },
  commandcode = { name = "Command Code", light = "assets/commandcode-light.svg", dark = "assets/commandcode-dark.svg" },
}

function M.iconPath(agent)
  local a = M.AGENTS[agent]
  if not a then
    return nil
  end
  return a.icon or (noctalia.isDarkMode() and a.light or a.dark)
end

function M.brandIcon(agent, size)
  local path = M.iconPath(agent)
  if not path then
    return ui.glyph({ name = "robot", size = size, color = "on_surface_variant" })
  end
  return ui.image({ path = path, width = size, height = size, fit = "contain" })
end

local function nowSec()
  return noctalia.nowMs() / 1000
end
M.nowSec = nowSec

function M.formatTokens(n)
  n = tonumber(n) or 0
  if n >= 1e9 then
    return string.format("%.1fB", n / 1e9)
  elseif n >= 1e6 then
    return string.format("%.1fM", n / 1e6)
  elseif n >= 1e3 then
    return string.format("%.1fK", n / 1e3)
  end
  return tostring(math.floor(n))
end

-- "4d 12h", "4h 42m", "12m"; nil when unknown.
function M.formatDuration(seconds)
  if seconds == nil then
    return nil
  end
  seconds = math.max(0, math.floor(seconds))
  local d = seconds // 86400
  local h = (seconds % 86400) // 3600
  local m = (seconds % 3600) // 60
  if d > 0 then
    return `{d}d {h}h`
  elseif h > 0 then
    return `{h}h {m}m`
  end
  return `{math.max(m, 1)}m`
end

-- Clock time of a future instant; adds the weekday once it is not today.
function M.formatClock(ts)
  if not ts then
    return nil
  end
  local sameDay = noctalia.formatTime("{:%Y%m%d}", ts) == noctalia.formatTime("{:%Y%m%d}", nowSec())
  return noctalia.formatTime(sameDay and "{:%-I:%M %p}" or "{:%a %-I:%M %p}", ts)
end

function M.titleCase(s)
  s = tostring(s or "")
  return (s:gsub("^%l", string.upper))
end

function M.money(v)
  v = tonumber(v)
  if not v then
    return nil
  end
  local sign = v < 0 and "-" or ""
  return string.format("%s$%.2f", sign, math.abs(v))
end

-- Live view of a quota window, including pace against the clock and a forecast.
-- A window whose reset time has passed has been emptied even if our fetch predates it.
function M.windowView(w)
  local now = nowSec()
  local used = math.clamp((tonumber(w.used) or 0) / 100, 0, 1)
  local resetsAt = tonumber(w.resetsAt)
  local duration = tonumber(w.duration)
  local view = { used = used, elapsed = nil, remaining = nil, resetsAt = resetsAt, pace = nil, limitIn = nil }
  if resetsAt and resetsAt <= now then
    view.used, view.resetsAt, view.expired = 0, nil, true
    return view
  end
  if resetsAt then
    view.remaining = resetsAt - now
    if duration and duration > 0 then
      view.elapsed = math.clamp(1 - view.remaining / duration, 0, 1)
      view.pace = used - view.elapsed
      -- Straight-line projection of the burn so far. The first minutes of a window say
      -- little about the rest, so wait until a tenth of it has passed (a limit already
      -- hit is reported regardless).
      local spent = duration * view.elapsed
      if used >= 1 then
        view.limitIn = 0
      elseif used > 0 and view.elapsed >= 0.1 then
        local toFull = (1 - used) / (used / spent)
        if toFull < view.remaining then
          view.limitIn = toFull
        end
      end
    end
  end
  return view
end

function M.usageColor(view)
  if view.used >= 0.9 or view.limitIn == 0 then
    return "error"
  elseif view.used >= 0.75 or view.limitIn then
    return "primary"
  end
  return "on_surface"
end

-- One line of context under a bar: amount used, pace, and when it resets or runs out.
function M.detailText(view)
  local parts = { `{math.floor(view.used * 100 + 0.5)}% used` }
  if view.pace then
    local points = math.floor(math.abs(view.pace) * 100 + 0.5)
    if points >= 2 then
      table.insert(parts, `{points}% {view.pace > 0 and "ahead of" or "under"} pace`)
    else
      table.insert(parts, "on pace")
    end
  end
  -- The forecast matters more than the reset clock; the countdown is already beside the bar.
  if view.limitIn == 0 then
    table.insert(parts, "limit reached")
  elseif view.limitIn then
    table.insert(parts, `limit in ~{M.formatDuration(view.limitIn)}`)
  elseif view.resetsAt then
    table.insert(parts, `resets {M.formatClock(view.resetsAt)}`)
  end
  return table.concat(parts, " · ")
end

-- Usage bar with a pace tick at the elapsed fraction of the window, built from
-- flex segments because ui.progress has no marker.
-- The host reuses retained nodes and keeps props a render omits, so every piece
-- has a stable key and sets width and flexGrow explicitly; otherwise the marker can
-- inherit a segment's flexGrow when the segment count changes.
function M.meter(view, height)
  height = height or 6
  local color = M.usageColor(view)
  local parts = {}
  local function seg(key, len, fill)
    if len > 0.002 then
      table.insert(parts, ui.box({
        key = key,
        width = 0,
        flexGrow = math.floor(len * 1000 + 0.5),
        height = height,
        radius = height / 2,
        fill = fill,
      }))
    end
  end
  local function marker()
    table.insert(parts, ui.box({ key = "marker", width = 2, flexGrow = 0, height = height + 8, radius = 1, fill = color }))
  end
  local used, elapsed = view.used, view.elapsed
  if elapsed == nil then
    seg("fill", used, color)
    seg("track", 1 - used, M.TRACK_COLOR)
  elseif used <= elapsed then
    seg("fill", used, color)
    seg("gap", elapsed - used, M.TRACK_COLOR)
    marker()
    seg("track", 1 - elapsed, M.TRACK_COLOR)
  else
    seg("fill", elapsed, color)
    marker()
    seg("over", used - elapsed, color)
    seg("track", 1 - used, M.TRACK_COLOR)
  end
  return ui.row({ flexGrow = 1, height = height + 8, align = "center", gap = 0 }, parts)
end

-- Tiny meter for the bar: a gauge filling upward on a horizontal bar, a short
-- left-to-right bar on a vertical one. One track with one fill avoids seams.
function M.miniMeter(view, barIsVertical)
  local LENGTH, THICKNESS = 16, 4
  local size = math.floor(LENGTH * view.used + 0.5)
  local children = {}
  if size > 0 then
    local fill = { radius = 2, fill = M.usageColor(view) }
    if barIsVertical then
      fill.width, fill.height = math.max(size, THICKNESS), THICKNESS
    else
      fill.width, fill.height = THICKNESS, math.max(size, THICKNESS)
    end
    fill.key = "fill"
    children[1] = ui.box(fill)
  end
  if barIsVertical then
    return ui.row({ width = LENGTH, height = THICKNESS, radius = 2, fill = M.TRACK_COLOR, justify = "start" }, children)
  end
  return ui.column({ width = THICKNESS, height = LENGTH, radius = 2, fill = M.TRACK_COLOR, justify = "end" }, children)
end

function M.activeAccount(section)
  if type(section) ~= "table" then
    return nil
  end
  for _, acct in ipairs(section.accounts or {}) do
    if acct.active then
      return acct
    end
  end
  return nil
end

function M.sessionWindow(entry)
  if type(entry) ~= "table" then
    return nil
  end
  for _, w in ipairs(entry.windows or {}) do
    if w.id == "session" or w.id == "primary" or w.id == "fiveHour" then
      return w
    end
  end
  return (entry.windows or {})[1]
end

-- Codex account behind an Amp ChatGPT subscription link, matched by login email.
function M.linkedCodex(data, provider)
  if type(data) ~= "table" or type(data.codex) ~= "table" or not provider or provider.email == "" then
    return nil
  end
  for _, acct in ipairs(data.codex.accounts or {}) do
    if acct.email and acct.email ~= "" and acct.email == provider.email then
      return acct
    end
  end
  return nil
end

-- When every used-up window of an account has reset; nil while it still has headroom.
function M.exhaustedUntil(acct)
  if type(acct) ~= "table" then
    return nil
  end
  local untilTs = nil
  for _, w in ipairs(acct.windows or {}) do
    local view = M.windowView(w)
    if view.used >= 1 and view.resetsAt then
      untilTs = math.max(untilTs or 0, view.resetsAt)
    end
  end
  return untilTs
end

-- The user's login PATH is not the shell's; prefix the usual tool locations.
function M.userCommand(cmd)
  return `PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH" {cmd}`
end

-- Launch the configured agent in a new terminal.
function M.launchAgent()
  local cmd = noctalia.string.trim(tostring(noctalia.getConfig("agent_command") or ""))
  noctalia.runInTerminal(M.userCommand(cmd ~= "" and cmd or "claude"))
end

function M.requestRefresh(force)
  noctalia.state.set(M.COMMAND_KEY, { action = "refresh", force = force == true, id = noctalia.nowMs() })
end

return M
