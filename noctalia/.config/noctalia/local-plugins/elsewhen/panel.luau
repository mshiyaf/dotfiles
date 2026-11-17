--!nonstrict
-- Elsewhen panel, laid out like Omarchy's: "It's 7:47 PM here in Delhi", a
-- "World (globe) Clock" title, then one card per city with its weather, date
-- (the local greeting on hover), time, zone and offset, and a 24-hour day strip
-- lit from sunrise to sunset with a marker at now.
--
-- Values are controls, as in Elsewhen: click a time for 12/24-hour, an offset
-- for relative/UTC, a temperature for °C/°F. Clicking a day strip moves every
-- clock to that time of day; clicking the header line (or reopening) returns to now.

local shared = require("./shared.luau")

local snapshot = noctalia.state.get(shared.STATE_KEY)
local cities = noctalia.state.get(shared.CITIES_KEY) or {}
local weather = noctalia.state.get(shared.WEATHER_KEY) or {}
local prefs = noctalia.state.get(shared.PREFS_KEY) or { hour24 = false, offsetMode = "home", units = "C" }

local isOpen = false
local editing = false
local adding = false
local query = ""
local found = {}
local searchCounter = 0
local lastMinute = -1

local hoveredRow = nil
local scrubMs = 0 -- offset of every clock from now while scrubbing

local CELLS = 48 -- half-hour cells per day strip
local GOLD = "#f2c14e"

local MONO = (function()
  noctalia.loadFont("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf")
  return noctalia.loadFont("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf")
end)()

local render

local function text(value, props)
  props = props or {}
  props.text = value
  props.fontFamily = MONO
  props.maxLines = props.maxLines or 1
  return ui.label(props)
end

local function muted(value, props)
  props = props or {}
  props.color = props.color or "on_surface_variant"
  props.fontSize = props.fontSize or 11
  return text(value, props)
end

local function now()
  return noctalia.nowMs() + scrubMs
end

local function setPrefs(change)
  local next = table.clone(prefs)
  for k, v in pairs(change) do
    next[k] = v
  end
  prefs = next
  shared.savePrefs(next)
  render()
end

local function save(list)
  cities = list
  shared.saveCities(list)
  render()
end

local function addCity(city)
  local list = table.clone(cities)
  table.insert(list, { label = city.label, id = city.id })
  adding = false
  query = ""
  found = {}
  save(list)
end

-- A clickable wrapper, since labels take no clicks.
local function clickable(key, onClick, children, tooltip)
  return ui.row({ key = key, gap = 4, align = "center", onClick = onClick, tooltip = tooltip }, children)
end

local function signedDuration(ms)
  local minutes = math.round(ms / 60000)
  if minutes == 0 then
    return ""
  end
  local abs = math.abs(minutes)
  local h, m = math.floor(abs / 60), abs % 60
  local body = h > 0 and (m > 0 and `{h}h {m}m` or `{h}h`) or `{m}m`
  return (minutes > 0 and "+" or "-") .. body
end

-- ── Header ───────────────────────────────────────────────────────────────────

local function header()
  local here = snapshot and snapshot.offsets and snapshot.offsets[snapshot.localZone]
  local line
  if here then
    local parts = shared.zoneParts(now(), here.offset)
    local time, meridiem = shared.formatTime(parts, prefs.hour24)
    local home = shared.homeCity(snapshot.localZone, shared.catalog())
    local children = {
      muted(`It's {time}{meridiem ~= "" and " " .. meridiem or ""} here in {home.label}`, { fontSize = 12 }),
    }
    if scrubMs ~= 0 then
      table.insert(children, muted(signedDuration(scrubMs), { fontSize = 12, color = "primary" }))
      table.insert(children, ui.glyph({ name = "x", size = 12, color = "primary" }))
      line = ui.row({
        gap = 8,
        justify = "center",
        tooltip = "Back to now",
        onClick = function()
          scrubMs = 0
          render()
        end,
      }, children)
    else
      line = ui.row({ gap = 8, justify = "center" }, children)
    end
  else
    line = muted("Reading time zones…", { fontSize = 12, textAlign = "center" })
  end

  local title = ui.row({ gap = 14, align = "center", justify = "center" }, {
    text("World", { fontSize = 17, fontWeight = "bold" }),
    ui.glyph({ name = "world", size = 34, color = "on_surface" }),
    text("Clock", { fontSize = 17, fontWeight = "bold" }),
  })

  local actions = ui.row({ gap = 4 }, {
    ui.button({
      key = "add",
      glyph = adding and "x" or "plus",
      variant = adding and "secondary" or "ghost",
      controlSize = "sm",
      tooltip = "Add a city",
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
      controlSize = "sm",
      tooltip = "Reorder or remove cities",
      enabled = #cities > 0,
      onClick = function()
        editing = not editing
        render()
      end,
    }),
  })

  return ui.column({ key = "header", gap = 6, align = "stretch" }, {
    line,
    ui.row({ align = "center" }, {
      ui.row({ width = 72 }, {}),
      ui.row({ flexGrow = 1, justify = "center" }, { title }),
      ui.row({ width = 72, justify = "end" }, { actions }),
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
      focus = true,
      onChange = "onSearchChange",
      onSubmit = "onSearchSubmit",
    }),
  }
  for i, city in ipairs(found) do
    table.insert(list, ui.row({
      key = `result-{i}-{city.id}`,
      gap = 8,
      align = "center",
      padding = 8,
      radius = 6,
      fill = i == 1 and "surface_variant/0.6" or "surface_variant/0.25",
      onClick = function()
        addCity(city)
      end,
    }, {
      text(city.label, { fontWeight = "bold", fontSize = 13 }),
      muted(city.id, { flexGrow = 1 }),
      city.offset and muted(shared.utcLabel(city.offset)) or nil,
    }))
  end
  if shared.trim(query) ~= "" and #found == 0 then
    table.insert(list, muted("No matching city or zone."))
  end
  return ui.column({ key = "search", gap = 6, align = "stretch" }, list)
end

-- ── Day strip ────────────────────────────────────────────────────────────────

-- Clicking cell `cell` of a city at `offset` moves every clock to the nearest
-- moment that city's wall clock reads that half hour.
local function scrubTo(cell, offset)
  local parts = shared.zoneParts(noctalia.nowMs(), offset)
  local current = parts.hour * 60 + parts.minute
  local delta = ((cell * 30 + 15 - current + 720) % 1440) - 720
  scrubMs = delta * 60000
end

local function dayStrip(index, row, fact)
  local rise, set = shared.daylight(fact, row.offset)
  local nowMinute = row.hour * 60 + row.minute
  local nowCell = math.floor(nowMinute / 30)
  local lit = shared.isLit(nowMinute, rise, set)
  local cells = {}
  for c = 0, CELLS - 1 do
    local key = `c{c}`
    local click = function()
      scrubTo(c, row.offset)
      render()
    end
    if c == nowCell then
      table.insert(cells, ui.box({
        key = key, width = 10, height = 10, radius = 5,
        fill = lit and GOLD or "on_surface",
        onClick = click,
      }))
    else
      local cellLit = shared.isLit(c * 30 + 15, rise, set)
      table.insert(cells, ui.box({
        key = key, flexGrow = 1, height = cellLit and 3 or 2,
        fill = cellLit and "on_surface_variant/0.75" or "on_surface_variant/0.2",
        onClick = click,
      }))
    end
  end
  local tip = nil
  if fact and fact.sunrise then
    local function hm(m)
      local t, mer = shared.formatTime({ hour = math.floor(m / 60), minute = m % 60 }, prefs.hour24)
      return mer ~= "" and `{t} {mer}` or t
    end
    tip = `Sunrise {hm(rise)} · Sunset {hm(set)}`
  end
  return ui.row({ key = "strip", height = 14, align = "center", tooltip = tip }, cells)
end

-- ── City cards ───────────────────────────────────────────────────────────────

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
    ui.button({ key = "up", glyph = "arrow-up", variant = "ghost", controlSize = "sm", enabled = index > 1, onClick = move(-1) }),
    ui.button({ key = "down", glyph = "arrow-down", variant = "ghost", controlSize = "sm", enabled = index < #cities, onClick = move(1) }),
    ui.button({
      key = "remove",
      glyph = "trash",
      variant = "ghost",
      controlSize = "sm",
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
  local key = `city-{index}-{city.id}-{city.label}`
  local row = shared.rowFor(city, snapshot, now(), prefs)
  if not row then
    return ui.row({ key = key, padding = 12, radius = 6, fill = "surface_variant/0.35" }, {
      text(city.label, { fontWeight = "bold", fontSize = 14 }),
    })
  end
  local fact = weather[shared.weatherKey(city)]
  local rise, set = shared.daylight(fact, row.offset)
  local lit = shared.isLit(row.hour * 60 + row.minute, rise, set)

  -- Name line: the city, then its weather on the right.
  local nameLine = { text(row.label, { fontWeight = "bold", fontSize = 14, flexGrow = 1 }) }
  if fact and fact.temp ~= nil then
    table.insert(nameLine, clickable("temp", function()
      setPrefs({ units = prefs.units == "F" and "C" or "F" })
    end, {
      muted(shared.formatTemp(fact.temp, prefs.units), { fontSize = 12 }),
      ui.glyph({ name = shared.weatherGlyph(fact.code, lit), size = 14, color = "on_surface_variant" }),
    }, "Click for °C / °F"))
  end

  -- Date line, or what people there are saying right now while hovered.
  local subLine
  local greet = hoveredRow == index and shared.greeting(row.id, row.hour)
  if greet then
    subLine = ui.row({ gap = 6 }, {
      ui.label({ text = greet.text, fontSize = 11, color = "primary", maxLines = 1 }),
      greet.roman ~= "" and muted(greet.roman) or nil,
    })
  else
    local date = row.dayLabel ~= "" and `{row.date} · {row.dayLabel}` or row.date
    subLine = muted(row.isHome and `{date} · Home` or date)
  end

  local right
  if editing then
    right = editControls(index)
  else
    local zoneLine = row.offsetText ~= "" and `{row.abbr} {row.offsetText}` or row.abbr
    right = ui.column({ gap = 0, align = "end" }, {
      clickable("time", function()
        setPrefs({ hour24 = not prefs.hour24 })
      end, {
        text(row.time, { fontSize = 22, fontWeight = "bold" }),
        row.meridiem ~= "" and muted(row.meridiem, { fontSize = 12 }) or nil,
      }, "Click for 12 / 24-hour"),
      clickable("offset", function()
        setPrefs({ offsetMode = prefs.offsetMode == "utc" and "home" or "utc" })
      end, { muted(zoneLine) }, "Click for offset from you / from UTC"),
    })
  end

  return ui.column({
    key = key,
    gap = 6,
    padding = 12,
    radius = 6,
    fill = hoveredRow == index and "surface_variant/0.55" or "surface_variant/0.35",
    onHover = function(state)
      hoveredRow = state == "true" and index or nil
      render()
    end,
  }, {
    ui.row({ gap = 12, align = "center" }, {
      ui.column({ flexGrow = 1, gap = 4 }, {
        ui.row({ gap = 8, align = "center" }, nameLine),
        subLine,
      }),
      right,
    }),
    dayStrip(index, row, fact),
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
  for i, city in ipairs(cities) do
    table.insert(body, cityCard(i, city))
  end
  if #cities == 0 then
    table.insert(body, muted("Setting up your cities…", { key = "empty" }))
  end
  panel.render(ui.scroll({ flexGrow = 1, gap = 10, padding = 16, align = "stretch" }, body))
end

for _, pair in ipairs({
  { shared.STATE_KEY, function(v) snapshot = v end },
  { shared.CITIES_KEY, function(v) cities = v end },
  { shared.WEATHER_KEY, function(v) weather = v end },
  { shared.PREFS_KEY, function(v) prefs = v end },
}) do
  noctalia.state.watch(pair[1], function(value)
    if type(value) == "table" then
      pair[2](value)
      render()
    end
  end)
end

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
  hoveredRow = nil
  scrubMs = 0
  lastMinute = -1
  panel.setWantsSecondTicks(true)
  render()
  -- Catch a DST change or a new system time zone, and refresh stale weather.
  shared.requestProbe()
end

function onClose()
  isOpen = false
  scrubMs = 0
  panel.setWantsSecondTicks(false)
end

function update()
  -- Clocks show minutes, so re-render only when the minute turns.
  local minute = math.floor(noctalia.nowMs() / 60000)
  if minute ~= lastMinute then
    lastMinute = minute
    render()
  end
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
