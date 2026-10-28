--!nonstrict

local STATE_KEY = "anime_matrix_state"
local PANEL_ID = "mshiyaf/anime-matrix:panel"
local snapshot = noctalia.state.get(STATE_KEY) or { loading = true }

local function render()
  local state = snapshot.state
  local color = state and state.enabled and "primary" or "on_surface_variant"
  barWidget.render(ui.row({ gap = 5, align = "center" }, {
    ui.glyph({ name = "sparkles", size = 17, color = color }),
    state and state.enabled and ui.label({ text = string.upper(state.brightness), fontSize = 11, color = color }) or nil,
  }))
  if snapshot.error and snapshot.error ~= "" then
    barWidget.setTooltip(`AniMe Matrix: {snapshot.error}`)
  elseif state then
    barWidget.setTooltip(`AniMe Matrix: {state.enabled and "on" or "off"} · {state.brightness} · {state.preset}`)
  else
    barWidget.setTooltip("AniMe Matrix: loading…")
  end
end

noctalia.state.watch(STATE_KEY, function(value)
  snapshot = value or snapshot
  render()
end)

function onClick()
  noctalia.togglePanel(PANEL_ID)
end

render()
