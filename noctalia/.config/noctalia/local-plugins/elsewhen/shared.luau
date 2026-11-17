--!nonstrict
-- Elsewhen model: zone offsets, wall clocks, the first-run city list, and search.
-- Ported from Omarchy's Elsewhen (shell/plugins/panels/elsewhen/Model.js, MIT, Jason Fried).
-- Pure functions except load/save; the `noctalia` global is only touched there.

local M = {}

M.STATE_KEY = "elsewhen_snapshot"
M.CITIES_KEY = "elsewhen_cities"
M.COMMAND_KEY = "elsewhen_command"
M.SEARCH_KEY = "elsewhen_search"
M.PANEL_ID = "mshiyaf/elsewhen:panel"

local DAY_START, DAY_END = 6, 18
local WEEKDAYS = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

function M.trim(text)
  return (string.gsub(string.gsub(text or "", "^%s+", ""), "%s+$", ""))
end

-- ── The date probe ───────────────────────────────────────────────────────────

-- argv for one `date` per zone, printing "Asia/Tokyo|JST|+0900", preceded by
-- "LOCAL|<zone>" and the local zone's own line. Without ids it probes every zone
-- the system knows (about 600 `date` calls, well under a second).
function M.probeCommand(ids)
  local script = "tz=$(timedatectl show -p Timezone --value); printf 'LOCAL|%s\\n' \"$tz\"; "
    .. 'if [ $# -eq 0 ]; then set -- $(timedatectl list-timezones); fi; set -- "$tz" "$@"; '
    .. 'for z in "$@"; do TZ="$z" date "+$z|%Z|%z"; done'
  local argv = { "/usr/bin/bash", "-c", script, "bash" }
  for _, id in ipairs(ids or {}) do
    table.insert(argv, id)
  end
  return argv
end

-- "-0700" -> -420, or nil.
function M.parseOffset(text)
  local sign, h, m = string.match(M.trim(text or ""), "^([+-])(%d%d)(%d%d)$")
  if not sign then
    return nil
  end
  local minutes = tonumber(h) * 60 + tonumber(m)
  return sign == "-" and -minutes or minutes
end

-- stdout -> localZone, { [zone] = { abbr, offset } }, sorted zone ids
function M.parseProbe(text)
  local localZone = ""
  local offsets = {}
  local ids = {}
  for line in string.gmatch(text or "", "[^\n]+") do
    local a, b, c = string.match(line, "^([^|]*)|([^|]*)|?([^|]*)$")
    if a == "LOCAL" then
      localZone = M.trim(b)
    elseif a and a ~= "" then
      local offset = M.parseOffset(c)
      if offset and not offsets[a] then
        offsets[a] = { abbr = M.trim(b), offset = offset }
        table.insert(ids, a)
      end
    end
  end
  table.sort(ids)
  return localZone, offsets, ids
end

-- ── Clock faces ──────────────────────────────────────────────────────────────

-- Wall clock at a UTC offset: shift the instant and convert days to a civil date
-- (Howard Hinnant's days_from_civil inverse), so no system time zone is involved.
function M.zoneParts(nowMs, offsetMinutes)
  local secs = math.floor(nowMs / 1000) + offsetMinutes * 60
  local days = math.floor(secs / 86400)
  local sod = secs - days * 86400
  local z = days + 719468
  local era = math.floor(z / 146097)
  local doe = z - era * 146097
  local yoe = math.floor((doe - math.floor(doe / 1460) + math.floor(doe / 36524) - math.floor(doe / 146096)) / 365)
  local doy = doe - (365 * yoe + math.floor(yoe / 4) - math.floor(yoe / 100))
  local mp = math.floor((5 * doy + 2) / 153)
  local month = mp < 10 and mp + 3 or mp - 9
  return {
    year = yoe + era * 400 + (month <= 2 and 1 or 0),
    month = month,
    day = doy - math.floor((153 * mp + 2) / 5) + 1,
    weekday = (days + 4) % 7 + 1, -- 1970-01-01 was a Thursday; 1 = Sunday
    hour = math.floor(sod / 3600),
    minute = math.floor(sod % 3600 / 60),
    days = days,
  }
end

local function pad2(n)
  return n < 10 and `0{n}` or tostring(n)
end

function M.formatTime(parts, hour24)
  if hour24 then
    return `{pad2(parts.hour)}:{pad2(parts.minute)}`, ""
  end
  local h = parts.hour % 12
  return `{h == 0 and 12 or h}:{pad2(parts.minute)}`, parts.hour < 12 and "AM" or "PM"
end

function M.formatDate(parts)
  return `{WEEKDAYS[parts.weekday]}, {MONTHS[parts.month]} {parts.day}`
end

function M.dayLabel(delta)
  if delta == 0 then
    return ""
  elseif delta == 1 then
    return "Tomorrow"
  elseif delta == -1 then
    return "Yesterday"
  end
  return delta > 0 and `+{delta} days` or `{delta} days`
end

-- "UTC", "UTC+2", "UTC-3:30".
function M.utcLabel(minutes)
  if minutes == 0 then
    return "UTC"
  end
  local abs = math.abs(minutes)
  local mins = abs % 60
  return `UTC{minutes < 0 and "-" or "+"}{math.floor(abs / 60)}{mins == 0 and "" or ":" .. pad2(mins)}`
end

-- "+9h", "-3.5h", or "" on the viewer's own offset.
function M.relativeLabel(offset, homeOffset)
  local diff = offset - homeOffset
  if diff == 0 then
    return ""
  end
  local hours = math.round(diff / 6) / 10
  local text = hours == math.floor(hours) and tostring(math.floor(hours)) or tostring(hours)
  return `{diff > 0 and "+" or ""}{text}h`
end

-- Everything a row needs; nil until the zone has been probed.
function M.rowFor(city, snapshot, nowMs, hour24, offsetMode)
  local offsets = snapshot and snapshot.offsets
  local info = offsets and offsets[city.id]
  local home = offsets and offsets[snapshot.localZone]
  if not info or not home then
    return nil
  end
  local parts = M.zoneParts(nowMs, info.offset)
  local here = M.zoneParts(nowMs, home.offset)
  local time, meridiem = M.formatTime(parts, hour24)
  return {
    label = city.label,
    id = city.id,
    abbr = info.abbr,
    time = time,
    meridiem = meridiem,
    hour = parts.hour,
    date = M.formatDate(parts),
    dayLabel = M.dayLabel(parts.days - here.days),
    daytime = parts.hour >= DAY_START and parts.hour < DAY_END,
    isHome = city.id == snapshot.localZone,
    offsetText = offsetMode == "utc" and M.utcLabel(info.offset) or M.relativeLabel(info.offset, home.offset),
  }
end

function M.isLitHour(hour)
  return hour >= DAY_START and hour < DAY_END
end

-- ── Cities ───────────────────────────────────────────────────────────────────

-- "America/Argentina/Buenos_Aires" -> "Buenos Aires"
function M.labelForZone(id)
  local last = string.match(id or "", "([^/]+)$") or id or ""
  return (string.gsub(last, "_", " "))
end

local catalog = nil

-- Well-known cities from cities.json: { label, id, rank } (rank 1 = best known).
function M.catalog()
  if catalog then
    return catalog
  end
  catalog = {}
  local raw = noctalia.readFile(`{noctalia.pluginDir()}/cities.json`)
  local decoded = raw and noctalia.json.decode(raw)
  for _, c in ipairs(decoded or {}) do
    if type(c) == "table" and type(c[1]) == "string" and type(c[2]) == "string" then
      table.insert(catalog, { label = c[1], id = c[2], rank = tonumber(c[5]) or 3 })
    end
  end
  return catalog
end

function M.homeCity(localZone, cat)
  for _, c in ipairs(cat) do
    if c.id == localZone then
      return { label = c.label, id = c.id }
    end
  end
  return { label = M.labelForZone(localZone), id = localZone }
end

-- The first-run list. Home is added in front when it isn't one of these.
local DEFAULT_CITIES = {
  { label = "Delhi", id = "Asia/Kolkata" },
  { label = "Dubai", id = "Asia/Dubai" },
  { label = "Riyadh", id = "Asia/Riyadh" },
  { label = "Toronto", id = "America/Toronto" },
  { label = "New York", id = "America/New_York" },
  { label = "London", id = "Europe/London" },
}

function M.seedCities(localZone, cat)
  local out = {}
  for _, c in ipairs(DEFAULT_CITIES) do
    if c.id == localZone then
      return table.clone(DEFAULT_CITIES)
    end
  end
  table.insert(out, M.homeCity(localZone, cat))
  for _, c in ipairs(DEFAULT_CITIES) do
    table.insert(out, { label = c.label, id = c.id })
  end
  return out
end

local function tracked(cities, id, label)
  for _, c in ipairs(cities) do
    if c.id == id and c.label == label then
      return true
    end
  end
  return false
end

-- Search entries, built once per probe: known cities first, then each zone under
-- its own name unless a better-known entry already has that name (the
-- America/Buenos_Aires link next to America/Argentina/Buenos_Aires).
function M.buildIndex(cat, zoneIds)
  local index = {}
  local names = {}
  local function add(label, id, base)
    local lower = string.lower(label)
    if base > 0 and names[lower] then
      return
    end
    names[lower] = true
    table.insert(index, { label = label, id = id, base = base, l = lower, z = string.lower(id) })
  end
  for _, c in ipairs(cat) do
    add(c.label, c.id, 0)
  end
  for _, id in ipairs(zoneIds or {}) do
    add(M.labelForZone(id), id, 3)
  end
  return index
end

-- Name prefix matches first, then name substrings, then zone id substrings;
-- known cities before zones within each.
function M.search(query, index, cities, limit)
  local q = string.lower(M.trim(query or ""))
  if q == "" then
    return {}
  end
  local scored = {}
  for order, e in ipairs(index) do
    local score = nil
    if string.sub(e.l, 1, #q) == q then
      score = e.base
    elseif string.find(e.l, q, 1, true) then
      score = e.base + 1
    elseif string.find(e.z, q, 1, true) then
      score = e.base + 2
    end
    if score and not tracked(cities, e.id, e.label) then
      table.insert(scored, { label = e.label, id = e.id, score = score, order = order })
    end
  end
  table.sort(scored, function(a, b)
    if a.score ~= b.score then
      return a.score < b.score
    end
    return a.order < b.order
  end)
  local out = {}
  for i = 1, math.min(limit, #scored) do
    table.insert(out, { label = scored[i].label, id = scored[i].id })
  end
  return out
end

-- ── Persistence (cities.json in the plugin's data dir) ──────────────────────

local function citiesFile()
  local dir = noctalia.pluginDataDir() or noctalia.expandPath("~/.local/state/noctalia/elsewhen")
  return `{dir}/cities.json`
end

-- nil when nothing has been saved yet (the first run seeds a list).
function M.loadCities()
  local raw = noctalia.readFile(citiesFile())
  local decoded = raw and noctalia.json.decode(raw)
  if type(decoded) ~= "table" then
    return nil
  end
  local out = {}
  for _, c in ipairs(decoded) do
    if type(c) == "table" and type(c.id) == "string" and type(c.label) == "string" then
      table.insert(out, { label = c.label, id = c.id })
    end
  end
  return out
end

function M.saveCities(cities)
  noctalia.writeFile(citiesFile(), noctalia.json.encode(cities))
  noctalia.state.set(M.CITIES_KEY, cities)
end

-- Search runs in the service: a scan of ~670 entries is too much for the panel's
-- per-callback CPU budget.
function M.requestSearch(query)
  noctalia.state.set(M.COMMAND_KEY, { action = "search", query = query, id = noctalia.nowMs() })
end

function M.requestProbe()
  noctalia.state.set(M.COMMAND_KEY, { action = "probe", id = noctalia.nowMs() })
end

return M
