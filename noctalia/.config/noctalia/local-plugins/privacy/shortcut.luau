--!nonstrict
local snapshot = noctalia.state.get("privacy_state") or { loading = true }

local function render()
  shortcut.setIcon("shield-lock")
  shortcut.setLabel(snapshot.loading and "Privacy…" or (snapshot.error and snapshot.error ~= "") and "Privacy error" or "Private mode")
  shortcut.setActive(snapshot.protected == true)
  shortcut.setEnabled(not snapshot.loading)
end

noctalia.state.watch("privacy_state", function(value)
  snapshot = value or snapshot
  render()
end)

function onClick()
  if not snapshot.loading then
    noctalia.state.set("privacy_command", { action = "toggle", id = noctalia.nowMs() })
  end
end

function onRightClick()
  noctalia.openSettings()
end

render()
