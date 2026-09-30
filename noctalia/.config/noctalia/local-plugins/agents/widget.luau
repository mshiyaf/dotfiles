--!nonstrict
-- Bar widget: tiny session meters for the live Claude and Codex accounts, plus a summary tooltip.

local shared = require("./shared.luau")

local snapshot = noctalia.state.get(shared.STATE_KEY) or { loading = true }

local function liveEntries(data)
  local out = {}
  local claude = shared.activeAccount(data.claude)
  if claude then
    table.insert(out, { agent = "claude", entry = claude })
  end
  local codex = shared.activeAccount(data.codex)
  if codex then
    table.insert(out, { agent = "codex", entry = codex })
  end
  return out
end

-- Compact value: percentage, then the forecast when it bites, else time to reset.
local function shortValue(view)
  local text = `{math.floor(view.used * 100 + 0.5)}% used`
  if view.limitIn == 0 then
    return text .. " · limit reached"
  elseif view.limitIn then
    return text .. ` · limit in {shared.formatDuration(view.limitIn)}`
  elseif view.remaining then
    return text .. ` · resets in {shared.formatDuration(view.remaining)}`
  end
  return text
end

local SHORT_NAME = { claude = "Claude", codex = "Codex", amp = "Amp", commandcode = "Command Code" }

local function tooltipRows(data)
  local rows = {}
  local tokens = type(data.tokensToday) == "table" and data.tokensToday.total or 0
  table.insert(rows, { key = "Tokens today", value = shared.formatTokens(tokens) })

  local function add(agent, entry, onlyIfUsed)
    if type(entry) ~= "table" then
      return
    end
    local name = SHORT_NAME[agent]
    if entry.status and entry.status ~= "ok" and shared.STATUS_TEXT[entry.status] then
      table.insert(rows, { key = name, value = shared.STATUS_TEXT[entry.status] })
    end
    for _, w in ipairs(entry.windows or {}) do
      local view = shared.windowView(w)
      if not onlyIfUsed or view.used > 0.005 then
        table.insert(rows, { key = `{name} {string.lower(w.label or "")}`, value = shortValue(view) })
      end
    end
  end

  for _, live in ipairs(liveEntries(data)) do
    add(live.agent, live.entry, false)
  end
  -- Pay-as-you-go style plans only earn a line once they are being used.
  add("amp", data.amp, true)
  add("commandcode", data.commandcode, true)

  local working = 0
  for _, s in ipairs(data.sessions or {}) do
    if s.status == "working" then
      working += 1
    end
  end
  if #(data.sessions or {}) > 0 then
    table.insert(rows, { key = "Sessions", value = `{working} working · {#data.sessions} open` })
  end
  return rows
end

local function render()
  local data = snapshot.data
  local vertical = barWidget.isVertical()
  local container = vertical and ui.column or ui.row
  local children = {}

  local style = noctalia.getConfig("bar_style") or "meters"
  local live = type(data) == "table" and liveEntries(data) or {}
  if style == "meters" and #live > 0 then
    for _, item in ipairs(live) do
      local w = shared.sessionWindow(item.entry)
      local group = { shared.brandIcon(item.agent, 14) }
      if w then
        table.insert(group, shared.miniMeter(shared.windowView(w), vertical))
      end
      table.insert(children, container({ key = item.agent, gap = 4, align = "center" }, group))
    end
  else
    local worst = nil
    for _, item in ipairs(live) do
      local w = shared.sessionWindow(item.entry)
      local view = w and shared.windowView(w)
      if view and (worst == nil or view.used > worst.used) then
        worst = view
      end
    end
    local color = worst and shared.usageColor(worst) or "on_surface"
    table.insert(children, ui.glyph({ name = "robot", size = 16, color = color }))
    if worst and noctalia.getConfig("show_percent") == true then
      table.insert(children, ui.label({ text = `{math.floor(worst.used * 100 + 0.5)}%`, color = color }))
    end
  end
  barWidget.render(container({ gap = 8, align = "center" }, children))

  if type(data) == "table" then
    barWidget.setTooltip(tooltipRows(data))
  elseif snapshot.error and snapshot.error ~= "" then
    barWidget.setTooltip(`Agents: {snapshot.error}`)
  else
    barWidget.setTooltip("Agents: loading…")
  end
end

noctalia.state.watch(shared.STATE_KEY, function(value)
  if type(value) == "table" then
    snapshot = value
    render()
  end
end)

-- Pace, forecasts, and window expiry move with the clock.
noctalia.setUpdateInterval(60000)
render()

function update()
  render()
end

function onClick()
  noctalia.togglePanel(shared.PANEL_ID)
end

function onRightClick()
  shared.requestRefresh(true)
end
