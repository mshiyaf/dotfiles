--!nonstrict
-- One owner for AniMe Matrix commands. The Python helper validates every value
-- and invokes asusctl with an argv array, never through a shell.

local STATE_KEY = "anime_matrix_state"
local COMMAND_KEY = "anime_matrix_command"
local helper = `{noctalia.pluginDir()}/controller.py`
local python = noctalia.fileExists("/usr/bin/python3") and "/usr/bin/python3" or "python3"

local snapshot = { loading = true, error = "", state = nil }

local function publish()
  noctalia.state.set(STATE_KEY, snapshot)
end

local function invoke(action, changes)
  snapshot.loading = true
  snapshot.error = ""
  publish()
  local encoded = changes and noctalia.json.encode(changes) or nil
  local args = encoded and { python, "-B", helper, action, encoded } or { python, "-B", helper, action }
  local started = noctalia.runAsync(args, function(result)
    local response = result and noctalia.json.decode(result.stdout or "")
    if type(response) == "table" and response.ok == true then
      snapshot.state = response.state
    else
      snapshot.error = (type(response) == "table" and response.error) or noctalia.string.trim(result and result.stderr or "") or "AniMe Matrix command failed"
    end
    snapshot.loading = false
    publish()
  end, 30000)
  if not started then
    snapshot.loading = false
    snapshot.error = "Could not start the AniMe Matrix controller"
    publish()
  end
end

noctalia.state.watch(COMMAND_KEY, function(command)
  if type(command) == "table" and type(command.changes) == "table" then
    invoke("apply", command.changes)
  end
end)

-- Refresh clocks and pick up settings changed by the standalone Studio.
noctalia.setUpdateInterval(60000)

function update()
  -- The controller also detects clocks inside Studio sequences.
  if not snapshot.loading then
    invoke("refresh")
  end
end

invoke("status")
