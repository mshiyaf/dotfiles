--!nonstrict
-- Headless loop: probes every zone's UTC offset and publishes it, owns the city
-- list (seeding it on the first run), and answers the panel's searches. The
-- widget and panel tick the clocks
-- locally against these offsets, which only move at DST boundaries.

local shared = require("./shared.luau")

local PROBE_EVERY_MS = 5 * 60 * 1000
local SEARCH_LIMIT = 6

local snapshot = { localZone = "", offsets = nil, updatedAt = 0 }
local cities = shared.loadCities()

local running = false
local lastProbeMs = 0

local function probe()
  if running then
    return
  end
  running = true
  local started = noctalia.runAsync(shared.probeCommand(nil), function(result)
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
  end, 20000)
  if not started then
    running = false
  end
end

-- Zone ids are matched by grep, not Luau: scanning all ~600 of them in one
-- callback exceeds Noctalia's per-callback CPU budget. Luau then ranks the few
-- matches together with the well-known cities.
local function search(query)
  local function publish(ids)
    local index = shared.buildIndex(shared.catalog(), ids)
    noctalia.state.set(shared.SEARCH_KEY, {
      query = query,
      results = shared.search(query, index, cities or {}, SEARCH_LIMIT),
    })
  end
  local q = shared.trim(query)
  if q == "" then
    publish({})
    return
  end
  local script = 'timedatectl list-timezones | grep -iF -- "${1// /_}" | head -n 30'
  local started = noctalia.runAsync({ "/usr/bin/bash", "-c", script, "bash", q }, function(result)
    local ids = {}
    for line in string.gmatch(result.stdout or "", "[^\n]+") do
      table.insert(ids, line)
    end
    publish(ids)
  end, 5000)
  if not started then
    publish({})
  end
end

noctalia.state.watch(shared.COMMAND_KEY, function(command)
  if type(command) ~= "table" then
    return
  end
  if command.action == "probe" then
    probe()
  elseif command.action == "search" then
    search(tostring(command.query or ""))
  end
end)

noctalia.state.watch(shared.CITIES_KEY, function(value)
  if type(value) == "table" then
    cities = value
  end
end)

if cities then
  noctalia.state.set(shared.CITIES_KEY, cities)
end
noctalia.setUpdateInterval(60000)
probe()

function update()
  if noctalia.nowMs() - lastProbeMs >= PROBE_EVERY_MS - 1000 then
    probe()
  end
end

function onIpc(event, _payload)
  if event == "refresh" then
    probe()
  end
end
