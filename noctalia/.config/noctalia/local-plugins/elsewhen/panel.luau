--!nonstrict
-- Elsewhen panel: the time here, then one row per city with its time, day, offset,
-- and a 24-hour daylight strip. "+" searches cities and zones to add; the pencil
-- reveals reorder and remove controls.

local shared = require("./shared.luau")

local snapshot = noctalia.state.get(shared.STATE_KEY)
local cities = noctalia.state.get(shared.CITIES_KEY) or {}
local isOpen = false
local editing = false
local adding = false
local query = ""
local found = {} -- results the service returned for `query`
local searchCounter = 0
local lastMinute = -1

local render

local function hour24()
  return noctalia.getConfig("hour24") == true
end

local function muted(text, props)
  props = props or {}
  props.text = text
  props.color = props.color or "on_surface_variant"
  props.fontSize = props.fontSize or 12
  props.maxLines = props.maxLines or 1
  return ui.label(props)
end

local function joined(parts)
  local out = {}
  for _, p in ipairs(parts) do
    if p and p ~= "" then
      table.insert(out, p)
    end
  end
  return table.concat(out, " · ")
end

local function save(list)
  cities = list
  shared.saveCities(list)
  render()
end

local function addCity(city)
  local list = table.clone(cities)
  table.insert(list, city)
  adding = false
  query = ""
  found = {}
  save(list)
end

-- ── Header ───────────────────────────────────────────────────────────────────

local function header()
  local here = snapshot and snapshot.offsets and snapshot.offsets[snapshot.localZone]
  local hero = {}
  if here then
    local parts = shared.zoneParts(noctalia.nowMs(), here.offset)
    local time, meridiem = shared.formatTime(parts, hour24())
    local home = shared.homeCity(snapshot.localZone, shared.catalog())
    hero = {
      ui.row({ gap = 6, align = "end" }, {
        ui.label({ text = time, fontSize = 34, fontWeight = "bold" }),
        meridiem ~= "" and ui.label({ text = meridiem, fontSize = 14, color = "on_surface_variant" }) or nil,
      }),
      ui.label({ text = joined({ home.label, shared.formatDate(parts) }), fontSize = 13, maxLines = 1 }),
      muted(joined({ here.abbr, shared.utcLabel(here.offset) })),
    }
  else
    hero = { muted("Reading time zones…", { fontSize = 13 }) }
  end

  return ui.row({ key = "header", gap = 12, align = "start" }, {
    ui.column({ flexGrow = 1, gap = 2 }, hero),
    ui.button({
      key = "add",
      glyph = adding and "x" or "plus",
      variant = adding and "secondary" or "ghost",
      onClick = function()
        adding = not adding
        query = ""
        found = {}
        searchCounter += 1
        render()
      end,
    }),
    ui.button({
      key = "edit",
      glyph = editing and "check" or "pencil",
      variant = editing and "primary" or "ghost",
      enabled = #cities > 0,
      onClick = function()
        editing = not editing
        render()
      end,
    }),
  })
end

-- ── Search ───────────────────────────────────────────────────────────────────

local function searchSection()
  local list = {
    ui.input({
      key = `search_{searchCounter}`,
      placeholder = "Add a city or time zone",
      value = query,
      onChange = "onSearchChange",
      onSubmit = "onSearchSubmit",
    }),
  }
  local offsets = snapshot and snapshot.offsets or {}
  for i, city in ipairs(found) do
    local info = offsets[city.id]
    table.insert(list, ui.row({
      key = `result-{i}-{city.id}`,
      gap = 8,
      align = "center",
      padding = 8,
      radius = 8,
      fill = i == 1 and "surface_variant/0.6" or "surface_variant/0.25",
      onClick = function()
        addCity(city)
      end,
    }, {
      ui.label({ text = city.label, fontWeight = "bold", maxLines = 1 }),
      muted(city.id, { flexGrow = 1 }),
      info and muted(shared.utcLabel(info.offset)) or nil,
    }))
  end
  if shared.trim(query) ~= "" and #found == 0 then
    table.insert(list, muted("No matching city or zone."))
  end
  return ui.column({ key = "search", gap = 6, align = "stretch" }, list)
end

-- ── City rows ────────────────────────────────────────────────────────────────

local function daylightStrip(currentHour)
  local cells = {}
  for h = 0, 23 do
    local fill
    if h == currentHour then
      fill = "primary"
    elseif shared.isLitHour(h) then
      fill = "primary/0.3"
    else
      fill = "on_surface_variant/0.12"
    end
    table.insert(cells, ui.box({ key = `h{h}`, flexGrow = 1, height = 5, radius = 2, fill = fill }))
  end
  return ui.row({ key = "strip", gap = 2 }, cells)
end

local function editControls(index)
  local function move(delta)
    return function()
      local list = table.clone(cities)
      local item = table.remove(list, index)
      table.insert(list, index + delta, item)
      save(list)
    end
  end
  return ui.row({ gap = 2, align = "center" }, {
    ui.button({ key = "up", glyph = "arrow-up", variant = "ghost", enabled = index > 1, onClick = move(-1) }),
    ui.button({ key = "down", glyph = "arrow-down", variant = "ghost", enabled = index < #cities, onClick = move(1) }),
    ui.button({
      key = "remove",
      glyph = "trash",
      variant = "ghost",
      enabled = #cities > 1,
      onClick = function()
        local list = table.clone(cities)
        table.remove(list, index)
        save(list)
      end,
    }),
  })
end

local function cityCard(index, city)
  local mode = noctalia.getConfig("offset_mode") or "home"
  local row = shared.rowFor(city, snapshot, noctalia.nowMs(), hour24(), mode)
  local key = `city-{index}-{city.id}-{city.label}`
  if not row then
    return ui.row({ key = key, padding = 12, radius = 10, fill = "surface_variant/0.35" }, {
      ui.label({ text = city.label, fontWeight = "bold" }),
    })
  end

  local right
  if editing then
    right = editControls(index)
  else
    right = ui.row({ gap = 4, align = "end" }, {
      ui.label({ text = row.time, fontSize = 20, fontWeight = "bold" }),
      row.meridiem ~= "" and muted(row.meridiem) or nil,
    })
  end

  -- "" rather than nil: a nil hole would end ipairs in joined() early.
  local sub = joined({ row.isHome and "Home" or "", row.dayLabel, row.abbr, row.offsetText })
  return ui.column({ key = key, gap = 8, padding = 12, radius = 10, fill = "surface_variant/0.35" }, {
    ui.row({ gap = 10, align = "center" }, {
      ui.glyph({
        name = row.daytime and "sun" or "moon",
        size = 18,
        color = row.daytime and "primary" or "on_surface_variant",
      }),
      ui.column({ flexGrow = 1, gap = 2 }, {
        ui.label({ text = row.label, fontWeight = "bold", maxLines = 1 }),
        muted(sub),
      }),
      right,
    }),
    daylightStrip(row.hour),
  })
end

render = function()
  if not isOpen then
    return
  end
  local body = { header() }
  if adding then
    table.insert(body, searchSection())
  end
  table.insert(body, ui.separator({ key = "sep" }))
  for i, city in ipairs(cities) do
    table.insert(body, cityCard(i, city))
  end
  if #cities == 0 then
    table.insert(body, muted("Setting up your cities…", { key = "empty" }))
  end
  panel.render(ui.scroll({ flexGrow = 1, gap = 12, padding = 20, align = "stretch" }, body))
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

-- Answers to earlier keystrokes can arrive late; only the current query's count.
noctalia.state.watch(shared.SEARCH_KEY, function(value)
  if type(value) == "table" and value.query == query then
    found = value.results or {}
    render()
  end
end)

function onOpen(_context)
  isOpen = true
  editing = false
  adding = false
  query = ""
  found = {}
  lastMinute = -1
  panel.setWantsSecondTicks(true)
  render()
  -- Catch a DST change or a new system time zone since the last probe.
  shared.requestProbe()
end

function onClose()
  isOpen = false
  panel.setWantsSecondTicks(false)
end

-- Clocks show minutes, so re-render only when the minute turns.
function update()
  local minute = math.floor(noctalia.nowMs() / 60000)
  if minute ~= lastMinute then
    lastMinute = minute
    render()
  end
end

function onConfigChanged()
  render()
end

function onSearchChange(value)
  query = value
  if shared.trim(value) == "" then
    found = {}
    render()
  else
    shared.requestSearch(value)
  end
end

-- Return adds the top result once the service has answered for this query.
function onSearchSubmit(value)
  if value == query and #found > 0 then
    addCity(found[1])
  end
end
