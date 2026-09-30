--!nonstrict
-- Headless loop: runs usage.py, publishes its snapshot, and sends quota notifications.

local shared = require("./shared.luau")

local TICK_MS = 60000
local THRESHOLDS = { 75, 90, 100 }

local snapshot = {
  loading = true,
  refreshing = false,
  error = "",
  data = nil,
  updatedAt = 0,
}

local running = false
local queued = false
local queuedForce = false
local lastFetchMs = 0

-- key -> { level = highest threshold already announced, resetsAt = window end we saw }
local notified = {}
local notifyFile = nil

local function intervalMs()
  local minutes = tonumber(noctalia.getConfig("refresh_minutes")) or 5
  return math.clamp(math.floor(minutes), 1, 60) * 60 * 1000
end

local function python()
  -- The login shell may put a version manager shim first; the system interpreter is stable.
  if noctalia.fileExists("/usr/bin/python3") then
    return "/usr/bin/python3"
  end
  return "python3"
end

local function dataDir()
  return noctalia.pluginDataDir() or noctalia.expandPath("~/.cache/noctalia-agents")
end

-- ── Notifications ────────────────────────────────────────────────────────────

local function loadNotified()
  notifyFile = `{dataDir()}/notified.json`
  local raw = noctalia.readFile(notifyFile)
  local decoded = raw and noctalia.json.decode(raw)
  if type(decoded) == "table" then
    notified = decoded
  end
end

-- The last snapshot is kept on disk so the bar has data right after login or a reload.
local function snapshotFile()
  return `{dataDir()}/last-snapshot.json`
end

local function loadLastSnapshot()
  local raw = noctalia.readFile(snapshotFile())
  local decoded = raw and noctalia.json.decode(raw)
  if type(decoded) == "table" and type(decoded.data) == "table" then
    snapshot.data = decoded.data
    snapshot.updatedAt = tonumber(decoded.updatedAt) or 0
    snapshot.loading = false
  end
end

local function saveLastSnapshot()
  local encoded = noctalia.json.encode({ data = snapshot.data, updatedAt = snapshot.updatedAt })
  if encoded then
    noctalia.writeFile(snapshotFile(), encoded)
  end
end

local function saveNotified()
  local encoded = noctalia.json.encode(notified)
  if encoded and notifyFile then
    noctalia.writeFile(notifyFile, encoded)
  end
end

-- Windows that are actually in use: the live account of each agent, plus Amp and Command Code.
local function trackedWindows(data)
  local out = {}
  local function add(agent, entry, suffix)
    if type(entry) ~= "table" then
      return
    end
    local name = shared.AGENTS[agent].name
    if suffix and suffix ~= "" then
      name = `{name} ({suffix})`
    end
    for _, w in ipairs(entry.windows or {}) do
      table.insert(out, { key = `{agent}:{entry.profile or ""}:{w.id}`, name = name, window = w })
    end
  end
  local claude = shared.activeAccount(data.claude)
  add("claude", claude, claude and claude.label)
  local codex = shared.activeAccount(data.codex)
  add("codex", codex, codex and codex.label)
  add("amp", data.amp)
  add("commandcode", data.commandcode)
  return out
end

local function checkNotifications(data)
  local thresholds = noctalia.getConfig("notify_thresholds") ~= false
  local resets = noctalia.getConfig("notify_resets") ~= false
  local now = shared.nowSec()
  local changed = false

  for _, t in ipairs(trackedWindows(data)) do
    local w = t.window
    local label = string.lower(w.label or "")
    local state = notified[t.key] or { level = 0, resetsAt = 0 }
    local view = shared.windowView(w)
    local resetsAt = tonumber(w.resetsAt) or 0

    -- A window that ended (by the clock, or a new end time) starts over.
    local rolled = (state.resetsAt > 0 and state.resetsAt <= now) or (resetsAt > state.resetsAt + 120 and state.resetsAt > 0)
    if rolled then
      if resets and state.level >= 75 then
        noctalia.notify(`{t.name} {label} reset`, "Your full quota is available again.")
      end
      state.level = 0
      state.resetsAt = 0
      changed = true
    end
    -- A stale fetch can still carry the old, already-passed end time; ignore it.
    if resetsAt > now and resetsAt ~= state.resetsAt then
      state.resetsAt = resetsAt
      changed = true
    end

    local pct = view.used * 100
    local level = 0
    for _, threshold in ipairs(THRESHOLDS) do
      if pct >= threshold then
        level = threshold
      end
    end
    if level > state.level then
      if thresholds then
        local left = view.resetsAt and ` Resets {shared.formatClock(view.resetsAt)}.` or ""
        local title = level >= 100 and `{t.name} {label} limit reached` or `{t.name} {label} at {math.floor(pct + 0.5)}%`
        local body = `{shared.detailText(view)}.`
        if level >= 100 then
          noctalia.notifyError(title, `Usage is capped until the window resets.{left}`)
        else
          noctalia.notify(title, body)
        end
      end
      state.level = level
      changed = true
    end
    notified[t.key] = state
  end
  if changed then
    saveNotified()
  end
end

-- ── Fetch loop ───────────────────────────────────────────────────────────────

local function publish()
  noctalia.state.set(shared.STATE_KEY, snapshot)
end

local refresh
local checkAmpFailover

local function finish()
  running = false
  snapshot.refreshing = false
  publish()
  if queued then
    local again = queuedForce
    queued, queuedForce = false, false
    refresh(again)
  end
end

refresh = function(force)
  if running then
    queued = true
    queuedForce = queuedForce or force == true
    return
  end
  running = true
  lastFetchMs = noctalia.nowMs()
  snapshot.refreshing = true
  publish()

  local args, encodeErr = noctalia.json.encode({
    codex_home = noctalia.getConfig("codex_home") or "~/.codex",
    cache_dir = dataDir(),
    force = force == true,
    -- A manual refresh may hit the APIs sooner, but never hammer them.
    api_min_age = force and 15 or 60,
  })
  if not args then
    snapshot.error = `config encode failed: {encodeErr}`
    snapshot.loading = false
    finish()
    return
  end

  local started = noctalia.runAsync({ python(), `{noctalia.pluginDir()}/usage.py`, "collect", args }, function(result)
    local data = nil
    if result and result.exitCode == 0 then
      data = noctalia.json.decode(result.stdout or "")
    end
    if type(data) == "table" then
      snapshot.data = data
      snapshot.error = ""
      snapshot.updatedAt = shared.nowSec()
      saveLastSnapshot()
      local ok, err = pcall(checkNotifications, data)
      if not ok then
        noctalia.log(`agents: notifications failed: {err}`)
      end
      ok, err = pcall(checkAmpFailover, data)
      if not ok then
        noctalia.log(`agents: amp failover failed: {err}`)
      end
    else
      local err = result and noctalia.string.trim(result.stderr or "") or ""
      if result and result.timedOut then
        err = "usage helper timed out"
      end
      snapshot.error = err ~= "" and err or "usage helper failed"
      noctalia.log(`agents: {snapshot.error}`)
    end
    snapshot.loading = false
    finish()
  end, 60000)

  if not started then
    snapshot.error = "could not start python3"
    snapshot.loading = false
    finish()
  end
end

-- ── Account switching ────────────────────────────────────────────────────────

local switching = false

local function switchAccount(provider, profile)
  if switching or type(profile) ~= "string" or not profile:match("^[%w][%w._-]*$") then
    return
  end
  if provider ~= "claude" and provider ~= "codex" then
    return
  end
  switching = true
  snapshot.switching = `{provider}:{profile}`
  publish()
  local cmd = shared.userCommand(`ai-account switch {provider} {profile}`)
  noctalia.runAsync(cmd, function(result)
    switching = false
    snapshot.switching = nil
    local name = shared.AGENTS[provider].name
    if result and result.exitCode == 0 then
      noctalia.notify(`{name} account switched`, noctalia.string.trim(result.stdout or ""))
    else
      local err = result and noctalia.string.trim(result.stderr or "") or ""
      noctalia.notifyError(`{name} account switch failed`, err ~= "" and err or "ai-account failed")
    end
    publish()
    refresh(true)
  end, 60000)
end

-- ── Amp model routing ────────────────────────────────────────────────────────
-- Amp routes a model to the first active linked subscription that maps it. A used-up
-- ChatGPT link keeps failing, so deactivating it hands GPT models to Amp's own plan.

-- { auto = { id, label, untilTs } | nil, paused = { [id] = untilTs } }
local failover = { auto = nil, paused = {} }
local ampBusy = false

local function failoverFile()
  return `{dataDir()}/amp-failover.json`
end

local function loadFailover()
  local raw = noctalia.readFile(failoverFile())
  local decoded = raw and noctalia.json.decode(raw)
  if type(decoded) == "table" then
    failover.auto = type(decoded.auto) == "table" and decoded.auto or nil
    failover.paused = type(decoded.paused) == "table" and decoded.paused or {}
  end
  snapshot.ampFailover = failover.auto
end

local function saveFailover()
  snapshot.ampFailover = failover.auto
  local encoded = noctalia.json.encode(failover)
  if encoded then
    noctalia.writeFile(failoverFile(), encoded)
  end
end

local function linkLabel(provider)
  local acct = shared.linkedCodex(snapshot.data, provider)
  return acct and acct.label ~= "" and `Codex {acct.label}` or provider.email ~= "" and provider.email or "ChatGPT"
end

local function setAmpProvider(provider, active, onDone)
  if ampBusy or type(provider) ~= "table" or not tostring(provider.id):match("^[%x-]+$") then
    return
  end
  ampBusy = true
  snapshot.ampBusy = provider.id
  publish()
  local verb = active and "activate" or "deactivate -y"
  noctalia.runAsync(shared.userCommand(`amp config model-providers {verb} {provider.id}`), function(result)
    ampBusy = false
    snapshot.ampBusy = nil
    local ok = result and result.exitCode == 0
    if not ok then
      local err = result and noctalia.string.trim(result.stderr ~= "" and result.stderr or result.stdout or "") or ""
      noctalia.notifyError("Amp routing change failed", err ~= "" and err or "amp config model-providers failed")
    end
    if onDone then
      onDone(ok)
    end
    publish()
    refresh(true)
  end, 60000)
end

local function findProvider(id)
  local amp = type(snapshot.data) == "table" and snapshot.data.amp
  for _, p in ipairs(type(amp) == "table" and amp.providers or {}) do
    if p.id == id then
      return p
    end
  end
  return nil
end

-- Manual choice from the panel. It pauses auto-failover for that link until the
-- linked account's used-up windows reset, so the user's decision sticks.
local function manualAmpProvider(id, active)
  local provider = findProvider(id)
  if not provider then
    return
  end
  local untilTs = shared.exhaustedUntil(shared.linkedCodex(snapshot.data, provider))
  if untilTs then
    failover.paused[id] = untilTs
  end
  if failover.auto and failover.auto.id == id then
    failover.auto = nil
  end
  saveFailover()
  setAmpProvider(provider, active, function(ok)
    if ok then
      local label = linkLabel(provider)
      noctalia.notify("Amp routing changed", active and `GPT models now use {label}.` or "GPT models now use Amp's own plan.")
    end
  end)
end

checkAmpFailover = function(data)
  local amp = data.amp
  if ampBusy or noctalia.getConfig("amp_auto_failover") == false or type(amp) ~= "table" then
    return
  end
  local now = shared.nowSec()
  local changed = false
  for id, untilTs in pairs(failover.paused) do
    if now >= (tonumber(untilTs) or 0) then
      failover.paused[id] = nil
      changed = true
    end
  end

  -- Restore the link we turned off once its windows have reset.
  local auto = failover.auto
  if auto then
    if now >= (tonumber(auto.untilTs) or 0) then
      local provider = findProvider(auto.id)
      failover.auto = nil
      saveFailover()
      -- Leave it alone if the user picked another ChatGPT link in the meantime.
      local otherActive = false
      for _, p in ipairs(amp.providers or {}) do
        if p.active and p.type == "openai_chatgpt" and p.id ~= auto.id then
          otherActive = true
        end
      end
      if provider and not provider.active and not otherActive then
        setAmpProvider(provider, true, function(ok)
          if ok then
            noctalia.notify("Amp back on your ChatGPT plan", `{auto.label} has quota again; GPT models use it once more.`)
          end
        end)
      end
    elseif changed then
      saveFailover()
    end
    return
  end

  for _, provider in ipairs(amp.providers or {}) do
    if provider.active and provider.type == "openai_chatgpt" and not failover.paused[provider.id] then
      local untilTs = shared.exhaustedUntil(shared.linkedCodex(data, provider))
      if untilTs then
        local label = linkLabel(provider)
        failover.auto = { id = provider.id, label = label, untilTs = untilTs }
        saveFailover()
        setAmpProvider(provider, false, function(ok)
          if ok then
            noctalia.notify("Amp switched to its own plan", `{label} is out of quota; back on it {shared.formatClock(untilTs)}.`)
          else
            failover.auto = nil
            saveFailover()
          end
        end)
        return
      end
    end
  end
  if changed then
    saveFailover()
  end
end

noctalia.state.watch(shared.COMMAND_KEY, function(command)
  if type(command) ~= "table" then
    return
  end
  if command.action == "refresh" then
    refresh(command.force == true)
  elseif command.action == "switch" then
    switchAccount(command.provider, command.profile)
  elseif command.action == "amp_provider" then
    manualAmpProvider(command.providerId, command.active == true)
  end
end)

loadNotified()
loadFailover()
loadLastSnapshot()
noctalia.setUpdateInterval(TICK_MS)
publish()
refresh(false)

-- Tick every minute: fetch on the configured interval, and re-check windows that
-- reset by the clock in between.
function update()
  if noctalia.nowMs() - lastFetchMs >= intervalMs() - 1000 then
    refresh(false)
  elseif snapshot.data then
    pcall(checkNotifications, snapshot.data)
    pcall(checkAmpFailover, snapshot.data)
    publish()
  end
end

function onConfigChanged()
  refresh(false)
end

function onIpc(event, _payload)
  if event == "refresh" then
    refresh(true)
  end
end
