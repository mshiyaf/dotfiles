--!nonstrict
-- Bar widget: a globe (optionally with the first other city's time) and a tooltip
-- of every tracked city.

local shared = require("./shared.luau")

local snapshot = noctalia.state.get(shared.STATE_KEY)
local cities = noctalia.state.get(shared.CITIES_KEY) or {}

local function rows()
  local hour24 = noctalia.getConfig("hour24") == true
  local mode = noctalia.getConfig("offset_mode") or "home"
  local out = {}
  for _, city in ipairs(cities) do
    local row = shared.rowFor(city, snapshot, noctalia.nowMs(), hour24, mode)
    if row then
      table.insert(out, row)
    end
  end
  return out
end

local function render()
  local all = rows()
  local vertical = barWidget.isVertical()
  local children = { ui.glyph({ key = "globe", name = "world", size = 16, color = "on_surface" }) }

  if noctalia.getConfig("show_city") == true and not vertical then
    for _, row in ipairs(all) do
      if not row.isHome then
        local text = `{row.label} {row.time}{row.meridiem ~= "" and " " .. row.meridiem or ""}`
        table.insert(children, ui.label({ key = "city", text = text, maxLines = 1 }))
        break
      end
    end
  end
  barWidget.render((vertical and ui.column or ui.row)({ gap = 6, align = "center" }, children))

  if #all == 0 then
    barWidget.setTooltip("Elsewhen: loading…")
    return
  end
  local tooltip = {}
  for _, row in ipairs(all) do
    local value = `{row.time}{row.meridiem ~= "" and " " .. row.meridiem or ""}`
    local extra = row.dayLabel ~= "" and row.dayLabel or row.offsetText
    if extra ~= "" then
      value ..= ` · {extra}`
    end
    table.insert(tooltip, { key = row.label, value = value })
  end
  barWidget.setTooltip(tooltip)
end

noctalia.state.watch(shared.STATE_KEY, function(value)
  if type(value) == "table" then
    snapshot = value
    render()
  end
end)

noctalia.state.watch(shared.CITIES_KEY, function(value)
  if type(value) == "table" then
    cities = value
    render()
  end
end)

noctalia.setUpdateInterval(15000)
render()

function update()
  render()
end

function onConfigChanged()
  render()
end

function onClick()
  noctalia.togglePanel(shared.PANEL_ID)
end
