--!nonstrict
-- Headless loop: probes the tracked zones' UTC offsets and publishes them, owns
-- the city list (seeding it on the first run), fetches weather, and answers the
-- panel's searches. The widget and panel tick the clocks locally against these
-- offsets, which only move at DST boundaries.

local shared = require("./shared.luau")

local PROBE_EVERY_MS = 5 * 60 * 1000
local SEARCH_LIMIT = 6

local snapshot = { localZone = "", offsets = nil, updatedAt = 0 }
local cities = shared.loadCities()

local running = false
local lastProbeMs = 0
local WEATHER_EVERY_MS = 20 * 60 * 1000
local weather = {}
local weatherRunning = false
local lastWeatherMs = 0
local weatherFor = ""

local function python()
  return noctalia.fileExists("/usr/bin/python3") and "/usr/bin/python3" or "python3"
end

-- Weather and sunrise/sunset for every tracked city; facts persist for the
-- session and a failed fetch keeps the previous ones.
local function fetchWeather(force)
  local list = cities or {}
  local key = noctalia.json.encode(list)
  local fresh = key == weatherFor and noctalia.nowMs() - lastWeatherMs < WEATHER_EVERY_MS
  if weatherRunning or #list == 0 or (fresh and not force) then
    return
  end
  weatherRunning = true
  local started = noctalia.runAsync({ python(), `{noctalia.pluginDir()}/weather.py`, key }, function(result)
    weatherRunning = false
    local decoded = result.exitCode == 0 and noctalia.json.decode(result.stdout or "")
    if type(decoded) ~= "table" then
      noctalia.log(`elsewhen: weather fetch failed ({result.exitCode}): {result.stderr or ""}`)
      return
    end
    lastWeatherMs = noctalia.nowMs()
    weatherFor = key
    for k, v in pairs(decoded) do
      weather[k] = v
    end
    noctalia.state.set(shared.WEATHER_KEY, weather)
  end, 30000)
  if not started then
    weatherRunning = false
  end
end

local function trackedIds()
  local ids = {}
  for _, c in ipairs(cities or shared.defaultCities()) do
    table.insert(ids, c.id)
  end
  return ids
end

local function probe()
  if running then
    return
  end
  running = true
  local started = noctalia.runAsync(shared.probeCommand(trackedIds()), function(result)
    running = false
    lastProbeMs = noctalia.nowMs()
    local localZone, offsets = shared.parseProbe(result.stdout)
    if result.exitCode ~= 0 or localZone == "" or not offsets[localZone] then
      noctalia.log(`elsewhen: zone probe failed ({result.exitCode}): {result.stderr or ""}`)
      return
    end
    snapshot = { localZone = localZone, offsets = offsets, updatedAt = lastProbeMs }
    noctalia.state.set(shared.STATE_KEY, snapshot)
    if cities == nil then
      cities = shared.seedCities(localZone, shared.catalog())
      shared.saveCities(cities)
    end
    fetchWeather(false)
  end, 20000)
  if not started then
    running = false
  end
end

-- Zone ids are matched by grep, not Luau: scanning all ~600 of them in one
-- callback exceeds Noctalia's per-callback CPU budget. The same script prices
-- those zones and the matching well-known cities, so every result has its offset.
local function search(query)
  local function publish(ids, offsets)
    local index = shared.buildIndex(shared.catalog(), ids)
    local results = shared.search(query, index, cities or {}, SEARCH_LIMIT)
    for _, r in ipairs(results) do
      r.offset = offsets[r.id] and offsets[r.id].offset
    end
    noctalia.state.set(shared.SEARCH_KEY, { query = query, results = results })
  end
  local q = shared.trim(query)
  if q == "" then
    publish({}, {})
    return
  end
  local argv = { "/usr/bin/bash", "-c",
    '{ timedatectl list-timezones | grep -iF -- "${1// /_}" | head -n 30; shift; printf "%s\\n" "$@"; } '
      .. '| sort -u | while read -r z; do TZ="$z" date "+$z|%Z|%z"; done',
    "bash", q }
  local lower = string.lower(q)
  for _, c in ipairs(shared.catalog()) do
    if string.find(string.lower(c.label), lower, 1, true) then
      table.insert(argv, c.id)
    end
  end
  local started = noctalia.runAsync(argv, function(result)
    local _, offsets, ids = shared.parseProbe(result.stdout)
    publish(ids, offsets)
  end, 5000)
  if not started then
    publish({}, {})
  end
end

noctalia.state.watch(shared.COMMAND_KEY, function(command)
  if type(command) ~= "table" then
    return
  end
  if command.action == "probe" then
    probe()
  elseif command.action == "refresh" then
    probe()
    fetchWeather(true)
  elseif command.action == "search" then
    search(tostring(command.query or ""))
  end
end)

noctalia.state.watch(shared.CITIES_KEY, function(value)
  if type(value) == "table" then
    cities = value
    probe() -- a new city needs its offset
    fetchWeather(false)
  end
end)

if cities then
  noctalia.state.set(shared.CITIES_KEY, cities)
end
noctalia.state.set(shared.PREFS_KEY, shared.loadPrefs())
noctalia.setUpdateInterval(60000)
probe()

function update()
  if noctalia.nowMs() - lastProbeMs >= PROBE_EVERY_MS - 1000 then
    probe()
  end
  fetchWeather(false)
end

function onIpc(event, _payload)
  if event == "refresh" then
    probe()
    fetchWeather(true)
  end
end
