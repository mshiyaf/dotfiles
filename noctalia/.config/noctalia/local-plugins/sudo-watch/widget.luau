--!nonstrict
-- Bar icon: red while sudo runs without a password, muted otherwise.

local WATCHED = { "/etc/sudoers", "/etc/sudoers.d" }

local active = false
local sources = {} -- sudoers entries that grant !authenticate
local checked = false
local running = false
local stamps = ""

-- Sudoers entries (file paths) whose block carries !authenticate.
local function passwordlessEntries(listing)
  local out = {}
  local current = nil
  for line in string.gmatch(listing or "", "[^\n]+") do
    local entry = string.match(line, "^Sudoers entry:%s*(.-):?%s*$")
    if entry then
      current = entry
    elseif current and string.find(line, "!authenticate", 1, true) then
      table.insert(out, current)
      current = nil
    end
  end
  return out
end

local function render()
  if not active and noctalia.getConfig("hide_when_inactive") == true then
    barWidget.render(ui.row({}, {}))
    barWidget.setTooltip("")
    return
  end
  barWidget.render(ui.glyph({
    name = active and "shield-lock" or "shield",
    size = 16,
    color = active and "error" or "on_surface_variant",
  }))
  if not checked then
    barWidget.setTooltip("Sudo: checking…")
  elseif active then
    local text = "Passwordless sudo is ACTIVE"
    if #sources > 0 then
      text ..= `\nGranted by: {table.concat(sources, ", ")}`
    end
    barWidget.setTooltip(text .. "\nClick to re-check")
  else
    barWidget.setTooltip("Sudo requires a password\nClick to re-check")
  end
end

local function probe()
  if running then
    return
  end
  running = true
  -- -n never prompts. Cached credentials can also make a listing succeed, so
  -- only the !authenticate tag counts as passwordless.
  local started = noctalia.runAsync({ "/usr/bin/sudo", "-n", "-l", "-l", "/usr/bin/true" }, function(result)
    running = false
    checked = true
    local entries = result.exitCode == 0 and passwordlessEntries(result.stdout) or {}
    local isActive = result.exitCode == 0 and string.find(result.stdout or "", "!authenticate", 1, true) ~= nil
    if isActive and not active then
      noctalia.notify("Passwordless sudo is active", "Any process running as you can run commands as root.")
    end
    active = isActive
    sources = entries
    render()
  end, 5000)
  if not started then
    running = false
  end
end

local function currentStamps()
  local parts = {}
  for _, path in ipairs(WATCHED) do
    local info = noctalia.fileInfo(path)
    table.insert(parts, info and tostring(info.mtime) or "-")
  end
  return table.concat(parts, "|")
end

stamps = currentStamps()
noctalia.setUpdateInterval(10000)
render()
probe()

-- Stat-only watch: a grant appears as a new or removed file in sudoers.d.
function update()
  local now = currentStamps()
  if now ~= stamps then
    stamps = now
    probe()
  end
end

function onConfigChanged()
  render()
end

function onClick()
  probe()
end
