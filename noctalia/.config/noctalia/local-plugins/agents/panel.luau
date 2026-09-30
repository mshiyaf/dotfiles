--!nonstrict
-- Agents panel: today's tokens, accounts and quota windows, and live sessions.

local shared = require("./shared.luau")

local snapshot = noctalia.state.get(shared.STATE_KEY) or { loading = true }
local isOpen = false
local ticks = 0

-- Two-step confirm for account switches: "provider:profile" armed until the deadline.
local armed = nil
local armedUntil = 0

local LABEL_WIDTH = 72
local TIME_WIDTH = 64
local CONFIRM_MS = 5000

local render

local function muted(text, props)
  props = props or {}
  props.text = text
  props.color = props.color or "on_surface_variant"
  props.fontSize = props.fontSize or 12
  return ui.label(props)
end

local function python()
  return noctalia.fileExists("/usr/bin/python3") and "/usr/bin/python3" or "python3"
end

local function statusLabel(status)
  local text = shared.STATUS_TEXT[status or ""]
  if not text then
    return nil
  end
  return ui.label({ text = text, color = "error", fontSize = 12, maxLines = 1 })
end

-- ── Quota windows ────────────────────────────────────────────────────────────

local function windowRows(key, w, detailed)
  local view = shared.windowView(w)
  local rows = {
    ui.row({ key = key, gap = 12, align = "center" }, {
      -- Fixed-width boxes keep every bar aligned; a label's width is only a hint.
      ui.row({ width = LABEL_WIDTH, minWidth = LABEL_WIDTH }, { ui.label({ text = w.label or "", maxLines = 1 }) }),
      shared.meter(view),
      ui.row({ width = TIME_WIDTH, minWidth = TIME_WIDTH, justify = "end" }, {
        muted(shared.formatDuration(view.remaining) or "", { fontSize = 13 }),
      }),
    }),
  }
  if detailed then
    local color = view.limitIn and "primary" or "on_surface_variant"
    if view.limitIn == 0 then
      color = "error"
    end
    table.insert(rows, ui.row({ key = key .. "-detail", gap = 12 }, {
      ui.row({ width = LABEL_WIDTH, minWidth = LABEL_WIDTH }, {}),
      muted(shared.detailText(view), { fontSize = 11, color = color, maxLines = 1 }),
    }))
  end
  return rows
end

local function addWindows(rows, keyPrefix, entry, detailed)
  for j, w in ipairs(entry.windows or {}) do
    for _, row in ipairs(windowRows(`{keyPrefix}-w-{j}`, w, detailed)) do
      table.insert(rows, row)
    end
  end
end

-- Section title: brand mark, name, then plan or status on the right.
local function sectionHeader(agent, right)
  local children = {
    shared.brandIcon(agent, 22),
    ui.label({ text = shared.AGENTS[agent].name, fontWeight = "bold", fontSize = 15 }),
    ui.spacer({ flexGrow = 1 }),
  }
  if right then
    table.insert(children, right)
  end
  return ui.row({ key = `{agent}-head`, gap = 10, align = "center" }, children)
end

local function planOrStatus(entry)
  return statusLabel(entry.status) or muted(shared.titleCase(entry.plan), { fontSize = 13 })
end

-- ── Accounts ─────────────────────────────────────────────────────────────────

local function accountAction(provider, acct)
  if acct.active then
    return ui.label({ text = "ACTIVE", color = "primary", fontWeight = "bold", fontSize = 12 })
  end
  if not acct.profile or acct.profile == "" then
    return nil
  end
  if acct.status == "signin" or acct.status == "missing" then
    return ui.button({
      text = "Sign in",
      variant = "outline",
      controlSize = "sm",
      onClick = function()
        panel.close()
        noctalia.runInTerminal(shared.userCommand(`ai-account login {provider} {acct.profile}`))
      end,
    })
  end
  local target = `{provider}:{acct.profile}`
  local isArmed = armed == target and noctalia.nowMs() < armedUntil
  local busy = snapshot.switching ~= nil
  local text = isArmed and "Confirm" or "Use"
  if busy and snapshot.switching == target then
    text = "Switching…"
  end
  return ui.button({
    text = text,
    variant = isArmed and "destructive" or "outline",
    controlSize = "sm",
    enabled = not busy,
    onClick = function()
      if isArmed then
        armed = nil
        noctalia.state.set(shared.COMMAND_KEY, { action = "switch", provider = provider, profile = acct.profile, id = noctalia.nowMs() })
      else
        armed, armedUntil = target, noctalia.nowMs() + CONFIRM_MS
      end
      render()
    end,
  })
end

local function codexExtras(rows, key, acct)
  local notes = {}
  local resets = acct.resets
  local available = type(resets) == "table" and (tonumber(resets.available) or 0) or 0
  if available > 0 then
    local line = `{available} free reset{available == 1 and "" or "s"}`
    local left = resets.nextExpiresAt and shared.formatDuration(resets.nextExpiresAt - shared.nowSec())
    if left then
      line ..= ` · next expires in {left}`
    end
    table.insert(notes, line)
  end
  local credits = acct.credits
  if type(credits) == "table" and (credits.has_credits or credits.unlimited) then
    table.insert(notes, credits.unlimited and "Unlimited credits" or `{credits.balance} credits`)
  end
  if acct.source == "logs" then
    table.insert(notes, "from session logs")
  end
  if #notes > 0 then
    table.insert(rows, muted(table.concat(notes, " · "), { key = key .. "-notes" }))
  end
end

local function accountSection(provider, section)
  local accounts = section.accounts or {}
  local rows = {}
  local managed = section.managed and #accounts > 0
  table.insert(rows, sectionHeader(provider, (not managed and accounts[1]) and planOrStatus(accounts[1]) or nil))

  for i, acct in ipairs(accounts) do
    local key = `{provider}-{i}`
    if managed then
      local line = { ui.label({ text = acct.label ~= "" and acct.label or `Account {i}`, fontWeight = "semibold" }) }
      if acct.plan and acct.plan ~= "" then
        table.insert(line, muted(`· {shared.titleCase(acct.plan)}`))
      end
      local status = statusLabel(acct.status)
      if status then
        table.insert(line, muted("·"))
        table.insert(line, status)
      end
      table.insert(line, ui.spacer({ flexGrow = 1 }))
      local action = accountAction(provider, acct)
      if action then
        table.insert(line, action)
      end
      table.insert(rows, ui.row({ key = key, gap = 6, align = "center" }, line))
      if provider == "codex" and armed == `codex:{acct.profile}` and noctalia.nowMs() < armedUntil then
        table.insert(rows, muted("Restarts the Codex daemon: running Codex CLI sessions are interrupted.", {
          key = key .. "-warn",
          color = "error",
          fontSize = 11,
          maxLines = 2,
        }))
      end
    end
    -- Full detail for the live account; inactive ones stay compact.
    addWindows(rows, key, acct, acct.active)
    if provider == "codex" then
      codexExtras(rows, key, acct)
    end
    if #(acct.windows or {}) == 0 and acct.status == "missing" and not managed then
      table.insert(rows, muted(`Run {provider} to sign in.`))
    end
  end
  return ui.column({ key = provider, gap = 10, align = "stretch" }, rows)
end

-- ── Amp / Command Code ───────────────────────────────────────────────────────

local function simpleSection(agent, entry, note)
  local rows = { sectionHeader(agent, planOrStatus(entry)) }
  addWindows(rows, agent, entry, true)
  if note and note ~= "" then
    table.insert(rows, muted(note, { key = agent .. "-note" }))
  end
  return ui.column({ key = agent, gap = 10, align = "stretch" }, rows)
end

local function ampNote(amp)
  local balance = shared.money(amp.balance)
  return balance and `Credits {balance}` or nil
end

-- Linked subscriptions Amp routes models through, with the matching Codex usage.
local function ampRouting(data, amp)
  local providers = amp.providers or {}
  if #providers == 0 then
    return {}
  end
  local rows = {}
  local servingOwn = true
  for _, p in ipairs(providers) do
    if p.active and p.type == "openai_chatgpt" then
      servingOwn = false
    end
  end

  local note
  local auto = snapshot.ampFailover
  if type(auto) == "table" then
    note = muted(`Auto-switched to Amp's plan · back on {auto.label} {shared.formatClock(auto.untilTs)}`, {
      key = "amp-route-note", color = "primary", fontSize = 11, maxLines = 2,
    })
  elseif servingOwn then
    note = muted("GPT models use Amp's own plan.", { key = "amp-route-note", fontSize = 11 })
  end
  table.insert(rows, ui.row({ key = "amp-route-head", gap = 8, align = "center" }, {
    muted("MODEL ROUTING", { fontWeight = "bold", fontSize = 11 }),
  }))

  for i, p in ipairs(providers) do
    local acct = p.type == "openai_chatgpt" and shared.linkedCodex(data, p) or nil
    local title = acct and `Codex {acct.label}` or (p.email ~= "" and p.email or p.name)
    local summary
    local summaryColor = "on_surface_variant"
    local untilTs = shared.exhaustedUntil(acct)
    if untilTs then
      summary = `Used up · resets {shared.formatClock(untilTs)}`
      summaryColor = "error"
    elseif acct then
      local parts = {}
      for _, w in ipairs(acct.windows or {}) do
        table.insert(parts, `{w.label} {math.floor(shared.windowView(w).used * 100 + 0.5)}%`)
      end
      summary = table.concat(parts, " · ")
    else
      summary = p.active and "Active" or "Inactive"
    end

    local busy = snapshot.ampBusy ~= nil
    local action
    if p.active then
      action = ui.button({
        text = snapshot.ampBusy == p.id and "Switching…" or "Use Amp plan",
        variant = "outline",
        controlSize = "sm",
        enabled = not busy,
        onClick = function()
          noctalia.state.set(shared.COMMAND_KEY, { action = "amp_provider", providerId = p.id, active = false, id = noctalia.nowMs() })
        end,
      })
    else
      action = ui.button({
        text = snapshot.ampBusy == p.id and "Switching…" or "Use",
        variant = "outline",
        controlSize = "sm",
        enabled = not busy,
        onClick = function()
          noctalia.state.set(shared.COMMAND_KEY, { action = "amp_provider", providerId = p.id, active = true, id = noctalia.nowMs() })
        end,
      })
    end

    local titleRow = { ui.label({ text = title, fontWeight = "semibold", maxLines = 1 }) }
    if p.active then
      table.insert(titleRow, ui.label({ text = "SERVING", color = "primary", fontWeight = "bold", fontSize = 11 }))
    end
    table.insert(rows, ui.row({ key = `amp-route-{i}`, gap = 10, align = "center" }, {
      shared.brandIcon(p.type == "openai_chatgpt" and "codex" or "amp", 16),
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.row({ gap = 8, align = "center" }, titleRow),
        muted(summary, { fontSize = 11, color = summaryColor, maxLines = 1 }),
      }),
      action,
    }))
  end
  if note then
    table.insert(rows, note)
  end
  return rows
end

local function ampSection(data, amp)
  local rows = { sectionHeader("amp", planOrStatus(amp)) }
  addWindows(rows, "amp", amp, true)
  local note = ampNote(amp)
  if note then
    table.insert(rows, muted(note, { key = "amp-note" }))
  end
  for _, row in ipairs(ampRouting(data, amp)) do
    table.insert(rows, row)
  end
  return ui.column({ key = "amp", gap = 10, align = "stretch" }, rows)
end


local function commandCodeNote(cc)
  local parts = {}
  local balance = shared.money(cc.balance)
  if balance then
    table.insert(parts, `{balance} credits`)
  end
  local left = cc.periodEndsAt and shared.formatDuration(cc.periodEndsAt - shared.nowSec())
  if left then
    table.insert(parts, `renews in {left}`)
  end
  return table.concat(parts, " · ")
end

-- ── Sessions ─────────────────────────────────────────────────────────────────

local STATUS_COLOR = { working = "primary", blocked = "error", waiting = "error", idle = "on_surface_variant" }

local function sessionsSection(sessions)
  local working = 0
  for _, s in ipairs(sessions) do
    if s.status == "working" then
      working += 1
    end
  end
  local rows = {
    ui.row({ key = "sessions-head", gap = 8, align = "center" }, {
      muted("SESSIONS", { fontWeight = "bold" }),
      ui.spacer({ flexGrow = 1 }),
      muted(`{#sessions} open · {working} working`),
    }),
  }
  for i, s in ipairs(sessions) do
    table.insert(rows, ui.row({
      key = `session-{s.paneId ~= "" and s.paneId or tostring(i)}`,
      gap = 10,
      padding = 8,
      radius = 8,
      align = "center",
      fill = s.focused and "surface_variant/0.8" or "surface_variant/0.35",
      onClick = function()
        panel.close()
        noctalia.runAsync({ python(), `{noctalia.pluginDir()}/usage.py`, "focus", s.paneId })
      end,
    }, {
      ui.box({ width = 8, height = 8, radius = 4, fill = STATUS_COLOR[s.status] or "on_surface_variant" }),
      shared.brandIcon(s.agent, 16),
      ui.column({ gap = 1, flexGrow = 1 }, {
        ui.label({ text = s.project ~= "" and s.project or s.cwd, fontWeight = "semibold", maxLines = 1 }),
        muted(s.title ~= "" and s.title or s.cwd, { fontSize = 11, maxLines = 1 }),
      }),
      muted(s.status, { fontSize = 11 }),
    }))
  end
  return ui.column({ key = "sessions", gap = 8, align = "stretch" }, rows)
end

-- ── Layout ───────────────────────────────────────────────────────────────────

local function header(data)
  local subtitle
  if type(data) == "table" and type(data.tokensToday) == "table" then
    subtitle = `{shared.formatTokens(data.tokensToday.total)} TOKENS TODAY`
  elseif snapshot.loading then
    subtitle = "LOADING…"
  else
    subtitle = "NO DATA"
  end
  return ui.row({ key = "header", gap = 14, align = "center" }, {
    ui.glyph({ name = "robot", size = 34, color = "on_surface" }),
    ui.column({ gap = 2, flexGrow = 1 }, {
      ui.label({ text = "Agents", fontWeight = "bold", fontSize = 18 }),
      muted(subtitle, { fontSize = 11, fontWeight = "semibold" }),
    }),
    ui.button({
      glyph = "refresh",
      variant = "ghost",
      controlSize = "sm",
      enabled = not snapshot.refreshing,
      onClick = function()
        shared.requestRefresh(true)
      end,
    }),
    ui.button({
      glyph = "plus",
      variant = "secondary",
      controlSize = "md",
      onClick = function()
        panel.close()
        shared.launchAgent()
      end,
    }),
  })
end

local function footer()
  local updated = tonumber(snapshot.updatedAt) or 0
  if updated <= 0 then
    return nil
  end
  local age = shared.nowSec() - updated
  local text = age < 60 and "Updated just now" or `Updated {shared.formatDuration(age)} ago`
  if snapshot.refreshing then
    text ..= " · refreshing…"
  end
  return muted(text, { key = "footer", fontSize = 11, textAlign = "center" })
end

render = function()
  if not isOpen then
    return
  end
  local data = snapshot.data
  local body = { header(data) }
  local function section(key, node)
    table.insert(body, ui.separator({ key = "sep-" .. key }))
    table.insert(body, node)
  end

  if snapshot.error and snapshot.error ~= "" then
    table.insert(body, ui.label({ key = "error", text = snapshot.error, color = "error", fontSize = 12, maxLines = 3 }))
  end

  if type(data) == "table" then
    if type(data.claude) == "table" and #(data.claude.accounts or {}) > 0 then
      section("claude", accountSection("claude", data.claude))
    end
    if type(data.codex) == "table" and data.codex.installed and #(data.codex.accounts or {}) > 0 then
      section("codex", accountSection("codex", data.codex))
    end
    if type(data.amp) == "table" and noctalia.getConfig("show_amp") ~= false then
      section("amp", ampSection(data, data.amp))
    end
    if type(data.commandcode) == "table" and noctalia.getConfig("show_commandcode") ~= false then
      section("commandcode", simpleSection("commandcode", data.commandcode, commandCodeNote(data.commandcode)))
    end
    if #(data.sessions or {}) > 0 and noctalia.getConfig("show_sessions") ~= false then
      section("sessions", sessionsSection(data.sessions))
    end
  end

  local foot = footer()
  if foot then
    table.insert(body, foot)
  end

  panel.render(ui.scroll({ flexGrow = 1, gap = 18, padding = 20, align = "stretch" }, body))
end

noctalia.state.watch(shared.STATE_KEY, function(value)
  if type(value) == "table" then
    snapshot = value
    render()
  end
end)

function onOpen(_context)
  isOpen = true
  ticks = 0
  armed = nil
  panel.setWantsSecondTicks(true)
  render()
  shared.requestRefresh(false)
end

function onClose()
  isOpen = false
  armed = nil
  panel.setWantsSecondTicks(false)
end

function update()
  ticks += 1
  -- Drop an expired switch confirmation promptly; otherwise re-render twice a minute.
  if armed and noctalia.nowMs() >= armedUntil then
    armed = nil
    render()
  elseif ticks % 30 == 0 then
    render()
  end
end
