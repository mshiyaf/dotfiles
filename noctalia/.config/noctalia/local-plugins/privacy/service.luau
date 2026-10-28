--!nonstrict
local KEY = "privacy_state"
local busy = false
local pending = nil
local snapshot = { loading = true, enabled = false, protected = false, error = "" }
local invoke
local uv = noctalia.expandPath("~/.local/bin/uv")
if not noctalia.fileExists(uv) then uv = "uv" end

local function publish()
  noctalia.state.set(KEY, snapshot)
end

invoke = function(action)
  if busy then
    if action ~= "status" then pending = action end
    return
  end
  busy = true
  snapshot.loading = true
  publish()
  local started = noctalia.runAsync({ uv, "run", "--script", `{noctalia.pluginDir()}/controller.py`, action }, function(result)
    local response = result and noctalia.json.decode(result.stdout or "")
    if type(response) == "table" then
      snapshot = response
    else
      snapshot.error = "Could not read privacy state"
      snapshot.protected = false
      if result then noctalia.log(result.stderr or "Privacy controller returned no output") end
    end
    snapshot.loading = false
    busy = false
    publish()
    if snapshot.error ~= "" then noctalia.log(snapshot.error) end
    if pending then
      local nextAction = pending
      pending = nil
      invoke(nextAction)
    end
  end, 60000)
  if not started then
    busy = false
    snapshot.loading = false
    snapshot.error = "Could not start privacy controller"
    snapshot.protected = false
    publish()
  end
end

noctalia.state.watch("privacy_command", function(command)
  if type(command) == "table" and command.action then invoke(command.action) end
end)

function onConfigChanged()
  invoke(noctalia.getConfig("private_mode") and "on" or "off")
end

function onIpc(event)
  if event == "toggle" or event == "on" or event == "off" or event == "status" then invoke(event) end
end

function update()
  invoke("status")
end

noctalia.setUpdateInterval(10000)
-- A shell/plugin restart must not silently turn off an existing private session.
invoke("status")
